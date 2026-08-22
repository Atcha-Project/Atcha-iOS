public protocol RefreshAlarmUseCase: Sendable {
    func execute() async throws -> AlarmInfo
}

public struct DefaultRefreshAlarmUseCase: RefreshAlarmUseCase {
    private let repository: any AlarmRepository

    public init(repository: any AlarmRepository) {
        self.repository = repository
    }

    public func execute() async throws -> AlarmInfo {
        try await repository.refresh()
    }
}
