public protocol PlaceRepository: Sendable {
    func searchPlaces(keyword: String, near coordinate: Coordinate?) async throws -> [Place]
    func reverseGeocode(_ coordinate: Coordinate) async throws -> Place
}
