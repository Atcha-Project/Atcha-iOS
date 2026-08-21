public protocol FetchHomeUseCase: Sendable {
    func execute() async throws -> HomeSummary
}

public struct DefaultFetchHomeUseCase: FetchHomeUseCase {
    private let repository: any HomeRepository

    public init(repository: any HomeRepository) {
        self.repository = repository
    }

    public func execute() async throws -> HomeSummary {
        try await repository.fetchHomeSummary()
    }
}
