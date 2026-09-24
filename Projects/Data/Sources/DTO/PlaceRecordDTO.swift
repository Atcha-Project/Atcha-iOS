import Domain

/// 로컬 저장용 장소 레코드 — Domain 엔티티는 Codable을 채택하지 않으므로 여기서 변환한다.
/// 최근 검색과 장소 응답 캐시가 같은 표현을 쓴다.
public struct PlaceRecordDTO: Codable, Equatable, Sendable {
    public let name: String
    public let address: String
    public let latitude: Double
    public let longitude: Double

    public init(_ place: Place) {
        name = place.name
        address = place.address
        latitude = place.coordinate.latitude
        longitude = place.coordinate.longitude
    }

    public func toEntity() -> Place {
        Place(name: name, address: address, coordinate: Coordinate(latitude: latitude, longitude: longitude))
    }
}
