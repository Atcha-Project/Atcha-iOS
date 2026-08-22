public protocol SearchPlacesUseCase: Sendable {
    func execute(keyword: String, near coordinate: Coordinate?) async throws -> [Place]
}

public struct DefaultSearchPlacesUseCase: SearchPlacesUseCase {
    private let repository: any PlaceRepository

    public init(repository: any PlaceRepository) {
        self.repository = repository
    }

    public func execute(keyword: String, near coordinate: Coordinate?) async throws -> [Place] {
        try await repository.searchPlaces(keyword: keyword, near: coordinate)
    }
}
