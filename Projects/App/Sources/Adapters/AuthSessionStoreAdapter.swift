import CoreAuth
import Domain

/// `SessionStoring` → `AuthSessionManager.adopt` 배선 — Domain이 CoreAuth를 모른 채
/// 게스트 발급 토큰을 세션에 채택시키는 다리.
struct AuthSessionStoreAdapter: SessionStoring {
    let sessionManager: AuthSessionManager

    func store(accessToken: String, refreshToken: String) async throws {
        try await sessionManager.adopt(
            TokenPair(accessToken: accessToken, refreshToken: refreshToken)
        )
    }
}
