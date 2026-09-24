import CoreNetwork
import Domain

/// 토큰 발급 응답 — 레거시 LoginDTO 실측 형태(전 필드 옵셔널, 좌표 키 "lat"/"lon")를
/// 게스트 발급도 그대로 쓴다고 제안했다. lat/lon은 미사용이라 디코딩만 한다.
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
