/// `GET /members/me` 결과 — 서버에 저장된 내 계정 정보.
/// 좌표는 서버가 lat·lon을 모두 줄 때만 성립한다(레거시 toEntity 규칙 계승).
public struct UserProfile: Sendable, Equatable {
    public let userID: Int?
    public let providerID: String?
    public let nickname: String?
    public let address: String?
    public let coordinate: Coordinate?
    public let appVersion: String?

    public init(
        userID: Int?,
        providerID: String?,
        nickname: String?,
        address: String?,
        coordinate: Coordinate?,
        appVersion: String?
    ) {
        self.userID = userID
        self.providerID = providerID
        self.nickname = nickname
        self.address = address
        self.coordinate = coordinate
        self.appVersion = appVersion
    }
}
