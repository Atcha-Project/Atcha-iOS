public protocol PlaceRepository: Sendable {
    func searchPlaces(keyword: String, near coordinate: Coordinate?) async throws -> [Place]
    func reverseGeocode(_ coordinate: Coordinate) async throws -> Place
    /// GET /locations/is-service-region — 서비스 지역(서울·경기·인천) 여부.
    func isServiceRegion(_ coordinate: Coordinate) async throws -> Bool
}
