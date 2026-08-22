import Foundation

public protocol RefreshAlarmUseCase: Sendable {
    func execute() async throws -> AlarmInfo
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

    public func execute() async throws -> AlarmInfo {
        let info = try await repository.refresh()
        // 시각 변경 시(로컬 알람이 사라진 경우 포함) 재스케줄한다.
        // 기대 발화 시각은 버퍼 반영값(AlarmTiming) — register와 동일한 기준으로 비교해야
        // 변경이 없어도 매 refresh마다 재스케줄되는 헛돎을 막는다.
        if let departure = info.departureTime {
            let expectedFireDate = AlarmTiming.alarmFireDate(departureTime: departure)
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
