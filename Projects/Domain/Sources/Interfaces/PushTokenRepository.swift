/// FCM 토큰 갱신의 서버 전달 — `PUT /members/me {fcmToken}`(서버 확정, 2026-09).
/// 게스트 발급 요청에도 토큰을 싣지만, 발급 이후의 갱신은 이 채널로만 간다.
public protocol PushTokenRepository: Sendable {
    func register(token: String) async throws
}
