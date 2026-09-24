import Foundation

public protocol RefreshAlarmUseCase: Sendable {
    /// - Parameter current: 로컬이 아는 세션. 도보 초의 출처이며, 재스케줄 시각 계산에
    ///   쓰인다. nil이면 버퍼만 적용된다(등록 경로와 같은 폴백).
    func execute(current: AlarmSession?) async throws -> AlarmRefreshOutcome
}

public struct DefaultRefreshAlarmUseCase: RefreshAlarmUseCase {
    private let repository: any AlarmRepository
    private let scheduler: any AlarmScheduler
    private let now: @Sendable () -> Date

    public init(
        repository: any AlarmRepository,
        scheduler: any AlarmScheduler,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.now = now
    }

    public func execute(current: AlarmSession?) async throws -> AlarmRefreshOutcome {
        let outcome = try await repository.refresh()
        // 서버가 세션 없음을 확정했으면 재스케줄할 대상 자체가 없다 — 그대로 올린다.
        guard case let .registered(info) = outcome else { return outcome }
        // 시각 변경 시(로컬 알람이 사라진 경우 포함) 재스케줄한다. 기대 발화 시각은
        // register와 같은 기준(출발 − 도보 − 버퍼)으로 비교해야 변경이 없어도 매
        // refresh마다 재스케줄되는 헛돎이 없다(이중 시각 금지).
        //
        // 도보 초를 직접 다루지 않는다 — `merging`이 routeId 일치까지 판단해 같은
        // 경로일 때만 보존하고, `fireDate`가 계산한다. 이전에는 이 파일이 스냅샷을
        // 직접 로드해 routeId를 비교했고, 같은 규칙이 AlarmSyncService에도 있었다.
        let expected = current?.merging(server: info, syncedAt: nil)
            ?? AlarmSession(server: info, local: .empty)
        guard let expectedFireDate = expected.fireDate else { return outcome }

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
        return outcome
    }
}
