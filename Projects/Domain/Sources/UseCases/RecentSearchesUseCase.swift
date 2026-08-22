public protocol RecentSearchesUseCase: Sendable {
    func fetch() async throws -> [Place]
    func save(_ place: Place) async throws
    func remove(_ place: Place) async throws
}

public struct DefaultRecentSearchesUseCase: RecentSearchesUseCase {
    private let repository: any RecentSearchRepository

    public init(repository: any RecentSearchRepository) {
        self.repository = repository
    }

    public func fetch() async throws -> [Place] {
        try await repository.recentSearches()
    }

    public func save(_ place: Place) async throws {
        try await repository.save(place)
    }

    public func remove(_ place: Place) async throws {
        try await repository.remove(place)
    }
}
