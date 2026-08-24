import Foundation

public protocol RefreshAlarmUseCase: Sendable {
    func execute() async throws -> AlarmInfo
}

public struct DefaultRefreshAlarmUseCase: RefreshAlarmUseCase {
    private let repository: any AlarmRepository
    private let scheduler: any AlarmScheduler
    /// 도보 초의 출처(Phase 14) — refresh 응답에는 도보 정보가 없으므로 등록 시점
    /// 스냅샷에서 읽는다. nil이면 버퍼만 적용(등록 경로와 같은 폴백).
    private let snapshotStore: (any AlarmSessionSnapshotStore)?
    private let now: @Sendable () -> Date

    public init(
        repository: any AlarmRepository,
        scheduler: any AlarmScheduler,
        snapshotStore: (any AlarmSessionSnapshotStore)? = nil,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.snapshotStore = snapshotStore
        self.now = now
    }

    public func execute() async throws -> AlarmInfo {
        let info = try await repository.refresh()
        // 시각 변경 시(로컬 알람이 사라진 경우 포함) 재스케줄한다.
        // 기대 발화 시각은 register와 같은 기준(출발 − 도보 − 버퍼)으로 비교해야
        // 변경이 없어도 매 refresh마다 재스케줄되는 헛돎이 없다(이중 시각 금지).
        if let departure = info.departureTime {
            let snapshot = await snapshotStore?.load()
            // 스냅샷의 도보 초는 같은 세션(routeId 일치)일 때만 유효하다 —
            // 서버가 다른 경로로 갈아탔으면 그 경로의 도보를 모른다(버퍼만 적용).
            let firstWalkSeconds = snapshot?.info.lastRouteId == info.lastRouteId
                ? snapshot?.firstWalkSeconds
                : nil
            let expectedFireDate = AlarmTiming.alarmFireDate(
                departureTime: departure,
                firstWalkSeconds: firstWalkSeconds
            )
            // 새 알람 시각이 이미 과거면 재스케줄하지 않는다 — 과거 fixed 스케줄은 AlarmKit이
            // 거부해 refresh 전체를 실패시킬 수 있다. 이 경우의 인지는 갱신 성공 이후
            // 훅의 즉시 최후통첩이 담당한다(정책 4 "알람 발화 후 변경").
            if expectedFireDate > now(),
               await scheduler.scheduledFireDate() != expectedFireDate {
                try await scheduler.replaceAlarm(
                    id: info.lastRouteId,
                    fireDate: expectedFireDate,
                    title: AlarmSchedulingDefaults.title
                )
            }
        }
        return info
    }
}
