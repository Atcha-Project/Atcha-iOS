/// 인증 도메인 API — 구현은 AtchaData.
/// 전부 서버 토큰 데코레이터를 타지 않는다(조합 루트가 plain client를 주입):
/// 게스트는 토큰 자체가 없고, 소셜 경로는 Authorization에 소셜 자격 증명을 실어야 한다.
public protocol AuthRepository: Sendable {
    /// POST /auth/guest — deviceId로 게스트 계정을 만들거나(최초) 되찾아(재호출) 토큰 쌍을 받는다.
    /// 토큰 불필요. 서버가 같은 deviceId에 같은 계정을 돌려주는 것이 재설치·토큰 소실 복구의 근거다.
    func signInAsGuest(deviceID: String, fcmToken: String?) async throws -> LoginSession

    /// GET /auth/check — 이 소셜 계정이 이미 가입돼 있는가.
    func checkRegistration(credential: SocialCredential) async throws -> Bool
    /// GET /auth/login — 소셜 자격 증명을 서버 토큰 쌍으로 교환.
    func login(credential: SocialCredential, fcmToken: String?) async throws -> LoginSession
    /// POST /auth/sign-up — 최소 가입 후 서버 토큰 쌍 수령(레거시 실측 계약).
    func signUp(credential: SocialCredential, form: SignUpForm, fcmToken: String?) async throws -> LoginSession
}
