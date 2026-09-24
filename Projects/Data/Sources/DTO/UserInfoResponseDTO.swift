import Domain

/// `GET /members/me` 응답(레거시 UserInfoResponse 실측) — 좌표 키는 "lat"/"lon",
/// appVersion만 비옵셔널. profileUrl은 V2 미사용이라 디코딩만 하고 버린다.
struct UserInfoResponseDTO: Decodable, Sendable {
    let id: Int?
    let providerId: String?
    let nickname: String?
    let profileUrl: String?
    let address: String?
    let lat: Double?
    let lon: Double?
    let appVersion: String

    func toEntity() -> UserProfile {
        let coordinate: Coordinate? = if let lat, let lon {
            Coordinate(latitude: lat, longitude: lon)
        } else {
            nil
        }
        return UserProfile(
            userID: id,
            providerID: providerId,
            nickname: nickname,
            address: address,
            coordinate: coordinate,
            appVersion: appVersion
        )
    }
}
