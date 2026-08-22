public protocol GetCurrentLocationUseCase: Sendable {
    func execute() async throws -> Coordinate
}

public struct DefaultGetCurrentLocationUseCase: GetCurrentLocationUseCase {
    private let locationService: any LocationService

    public init(locationService: any LocationService) {
        self.locationService = locationService
    }

    public func execute() async throws -> Coordinate {
        try await locationService.currentLocation()
    }
}
