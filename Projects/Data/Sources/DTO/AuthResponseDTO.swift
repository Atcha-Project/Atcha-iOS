import CoreNetwork
import Domain

/// `/auth/guest` 응답 — 전 필드 옵셔널, 좌표 키는 "lat"/"lon".
/// lat/lon(집 좌표)은 현 스코프 미사용이라 디코딩만 하고 엔티티로 올리지 않는다.
struct LoginResponseDTO: Decodable, Sendable {
    let id: Int?
    let accessToken: String?
    let refreshToken: String?
    let lat: Double?
    let lon: Double?

    func toEntity() throws -> LoginSession {
        guard let accessToken, let refreshToken else {
            throw NetworkError.decoding(underlying: MissingResultError())
        }
        return LoginSession(userID: id, accessToken: accessToken, refreshToken: refreshToken)
    }
}
