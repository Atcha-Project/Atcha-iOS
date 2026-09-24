/// FCM 토큰 갱신의 서버 전달 — 로그인/가입 파라미터 외의 채널(미확정 #5).
/// 서버 경로가 확정되기 전까지 App은 no-op 구현을 주입한다.
public protocol PushTokenRepository: Sendable {
    func register(token: String) async throws
}
