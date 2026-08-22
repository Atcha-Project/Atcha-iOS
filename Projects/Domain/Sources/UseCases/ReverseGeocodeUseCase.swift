public protocol ReverseGeocodeUseCase: Sendable {
    func execute(coordinate: Coordinate) async throws -> Place
}

public struct DefaultReverseGeocodeUseCase: ReverseGeocodeUseCase {
    private let repository: any PlaceRepository

    public init(repository: any PlaceRepository) {
        self.repository = repository
    }

    public func execute(coordinate: Coordinate) async throws -> Place {
        try await repository.reverseGeocode(coordinate)
    }
}
