/// 게스트 인증 API — 구현은 AtchaData. 토큰 없이 호출하는 발급 계약이라 서버 토큰 데코레이터를
/// 타지 않는다(조합 루트가 plain client를 주입).
public protocol AuthRepository: Sendable {
    /// POST /auth/guest(서버 합의 대기 중인 제안 계약) — 기기 ID로 게스트 토큰 쌍을 발급받는다.
    /// 같은 deviceID면 같은 게스트 회원을 돌려줘야 한다(재설치·refresh 만료 후에도 알람·집 주소 유지).
    func issueGuestSession(deviceID: String, fcmToken: String?) async throws -> LoginSession
}
