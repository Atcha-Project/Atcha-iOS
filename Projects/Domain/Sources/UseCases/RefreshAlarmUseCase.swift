import Foundation

public protocol RefreshAlarmUseCase: Sendable {
    func execute() async throws -> AlarmInfo
}

public struct DefaultRefreshAlarmUseCase: RefreshAlarmUseCase {
    private let repository: any AlarmRepository
    private let scheduler: any AlarmScheduler

    public init(repository: any AlarmRepository, scheduler: any AlarmScheduler) {
        self.repository = repository
        self.scheduler = scheduler
    }

    public func execute() async throws -> AlarmInfo {
        let info = try await repository.refresh()
        // 시각 변경 시(로컬 알람이 사라진 경우 포함) 재스케줄한다.
        if let departure = info.departureTime,
           await scheduler.scheduledFireDate() != departure {
            try await scheduler.replaceAlarm(
                id: info.lastRouteId,
                fireDate: departure,
                title: AlarmSchedulingDefaults.title
            )
        }
        return info
    }
}
