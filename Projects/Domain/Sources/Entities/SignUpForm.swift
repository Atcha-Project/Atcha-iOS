/// `POST /auth/sign-up` 입력 — V2는 온보딩 화면 없이 최소 가입으로 보낸다.
/// 집 주소·알림 빈도는 가입 후 `/members/me` PATCH로 언제든 바꿀 수 있다.
public struct SignUpForm: Sendable, Equatable {
    public let userName: String?
    public let address: String
    public let coordinate: Coordinate
    public let alertFrequencies: [Int]

    public init(
        userName: String?,
        address: String,
        coordinate: Coordinate,
        alertFrequencies: [Int]
    ) {
        self.userName = userName
        self.address = address
        self.coordinate = coordinate
        self.alertFrequencies = alertFrequencies
    }

    /// 레거시 실측 기본 알림 빈도(HomeFindViewModel): 1분·10분 전.
    public static let defaultAlertFrequencies = [1, 10]

    /// 위치를 확보하지 못했을 때의 폼 — 레거시가 실제로 보내던 값
    /// (userName ""·address ""·좌표 (0,0))이라 서버 수용이 실측돼 있다.
    public static let minimalFallback = SignUpForm(
        userName: "",
        address: "",
        coordinate: Coordinate(latitude: 0, longitude: 0),
        alertFrequencies: defaultAlertFrequencies
    )
}
