/// 계정 도메인 API(`/members/me` 계열) — 구현은 AtchaData, 서버 토큰 데코레이터 적용 대상.
public protocol UserRepository: Sendable {
    /// GET /members/me — 내 계정 정보 조회.
    func fetchMe() async throws -> UserProfile
    /// PATCH /members/me/home-address — 집 주소 변경.
    func updateHomeAddress(address: String?, coordinate: Coordinate?) async throws
    /// PATCH /members/me/alert-frequency — 알림 빈도 변경.
    func updateAlertFrequencies(_ frequencies: [Int]) async throws
}
