/// 서버 토큰 채택 포트 — Domain이 CoreAuth를 모른 채 로그인 결과를 세션에 반영한다.
/// 어댑터는 App에서 `AuthSessionManager.adopt(_:)`로 배선.
public protocol SessionStoring: Sendable {
    func store(accessToken: String, refreshToken: String) async throws
}
