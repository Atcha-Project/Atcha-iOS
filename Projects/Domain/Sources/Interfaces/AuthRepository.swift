/// 인증 도메인 API — 구현은 AtchaData.
/// 게스트는 토큰 자체가 없으므로 서버 토큰 데코레이터를 타지 않는다
/// (조합 루트가 plain client를 주입).
public protocol AuthRepository: Sendable {
    /// POST /auth/guest — deviceId로 게스트 계정을 만들거나(최초) 되찾아(재호출) 토큰 쌍을 받는다.
    /// 토큰 불필요. 서버가 같은 deviceId에 같은 계정을 돌려주는 것이 재설치·토큰 소실 복구의 근거다.
    func signInAsGuest(deviceID: String, fcmToken: String?) async throws -> LoginSession
}
