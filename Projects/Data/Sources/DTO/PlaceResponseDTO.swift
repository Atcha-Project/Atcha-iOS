import Domain

public struct PlaceResponseDTO: Decodable, Sendable {
    public let name: String?
    public let lat: Double?
    public let lon: Double?
    public let businessCategory: String?
    public let address: String?
    public let radius: String?

    /// 레거시는 6필드 전부 non-nil이어야 항목을 살렸지만, 이름·좌표만 있으면 표시엔 충분하다.
    public func toEntity() -> Place? {
        guard let name, let lat, let lon else { return nil }
        return Place(name: name, address: address ?? "", coordinate: Coordinate(latitude: lat, longitude: lon))
    }
}
