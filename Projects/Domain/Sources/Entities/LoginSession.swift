/// 게스트 발급(`/auth/guest`) 결과 — 서버 토큰 쌍.
/// 응답의 집 좌표(lat/lon)는 쓰지 않으므로 엔티티에서 생략한다(DTO만 디코딩).
public struct LoginSession: Sendable, Equatable {
    public let userID: Int?
    public let accessToken: String
    public let refreshToken: String

    public init(userID: Int?, accessToken: String, refreshToken: String) {
        self.userID = userID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
