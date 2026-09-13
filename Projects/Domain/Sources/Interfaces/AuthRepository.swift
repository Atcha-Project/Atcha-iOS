/// 로그인 도메인 API(`/auth/check`·`/auth/login`·`/auth/sign-up`) — 구현은 AtchaData.
/// 소셜 자격 증명을 Bearer로 보내는 특수 계약이라 서버 토큰 데코레이터를 타지 않는다
/// (조합 루트가 plain client를 주입).
public protocol AuthRepository: Sendable {
    /// GET /auth/check — 이 소셜 계정이 이미 가입돼 있는가.
    func checkRegistration(credential: SocialCredential) async throws -> Bool
    /// GET /auth/login — 소셜 자격 증명을 서버 토큰 쌍으로 교환.
    func login(credential: SocialCredential, fcmToken: String?) async throws -> LoginSession
    /// POST /auth/sign-up — 최소 가입 후 서버 토큰 쌍 수령(레거시 실측 계약).
    func signUp(credential: SocialCredential, form: SignUpForm, fcmToken: String?) async throws -> LoginSession
}
