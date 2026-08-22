public protocol CancelAlarmUseCase: Sendable {
    func execute(lastRouteId: String) async throws
}

public struct DefaultCancelAlarmUseCase: CancelAlarmUseCase {
    private let repository: any AlarmRepository
    private let scheduler: any AlarmScheduler

    public init(repository: any AlarmRepository, scheduler: any AlarmScheduler) {
        self.repository = repository
        self.scheduler = scheduler
    }

    public func execute(lastRouteId: String) async throws {
        try await repository.cancel(lastRouteId: lastRouteId)
        await scheduler.cancelAlarm()
    }
}
