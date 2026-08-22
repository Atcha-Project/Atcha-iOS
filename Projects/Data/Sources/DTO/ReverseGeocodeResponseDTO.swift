import Domain

public struct ReverseGeocodeResponseDTO: Decodable, Sendable {
    public let name: String?
    public let address: String?
    public let lat: Double?
    public let lon: Double?

    public func toEntity() -> Place? {
        guard let name, let lat, let lon else { return nil }
        return Place(name: name, address: address ?? "", coordinate: Coordinate(latitude: lat, longitude: lon))
    }
}
