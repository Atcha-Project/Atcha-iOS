import CoreNetwork

/// Owns the anonymous session lifecycle: first-launch issuance, token refresh
/// via GET /auth/reissue, and the 401-recovery chain. Single-flight is
/// guaranteed by keeping the in-progress recovery task on the actor — the
/// legacy interceptor's waiting-queue semantics without the queue.
public actor AuthSessionManager {
    /// Read synchronously by the decorator on every request (no actor hop);
    /// TokenStore is a Sendable value and the keychain store locks internally.
    public nonisolated let tokenStore: TokenStore

    /// Must be the plain (undecorated) client — the legacy setup used a
    /// separate interceptor-free session for reissue to break recursion.
    private let networkClient: any NetworkClient
    private let issuer: any AnonymousSessionIssuing
    private var recoveryTask: Task<Void, any Error>?

    public init(
        tokenStore: TokenStore,
        networkClient: any NetworkClient,
        issuer: any AnonymousSessionIssuing
    ) {
        self.tokenStore = tokenStore
        self.networkClient = networkClient
        self.issuer = issuer
    }

    /// Splash-time bootstrap. Issues an anonymous session only when no access
    /// token is stored. `issuerNotConfigured` is non-fatal (미확정 입력 #2's
    /// interim behavior: proceed without tokens); other failures propagate so
    /// the splash can offer retry.
    public func bootstrap() async throws {
        if (try? tokenStore.accessToken()) != nil { return }
        do {
            try tokenStore.save(try await issuer.issueSession())
        } catch AuthError.issuerNotConfigured {
            return
        }
    }

    /// Single entry point for 401 recovery: refresh first, fall back to a
    /// fresh anonymous session, throw when both are impossible. Concurrent
    /// callers join the in-flight recovery instead of starting another.
    public func recoverSession() async throws {
        if let existing = recoveryTask {
            return try await existing.value
        }
        let task = Task { try await self.performRecovery() }
        recoveryTask = task
        defer { recoveryTask = nil }
        try await task.value
    }

    private func performRecovery() async throws {
        if let refreshToken = try? tokenStore.refreshToken() {
            do {
                return try await refreshTokens(with: refreshToken)
            } catch {
                // Refresh is dead (rejected, expired, transport) — fall back
                // to re-issuing an anonymous session.
            }
        }
        // Existing tokens are never cleared here: save() overwrites on
        // success, and a transient failure must not destroy the anonymous
        // identity that owns server-side state.
        try tokenStore.save(try await issuer.issueSession())
    }

    private func refreshTokens(with refreshToken: String) async throws {
        let envelope = try await networkClient.request(
            ReissueEndpoint(refreshToken: refreshToken),
            as: ReissueEnvelope.self
        )
        guard envelope.responseCode == "SUCCESS", let tokens = envelope.result else {
            throw AuthError.refreshRejected(responseCode: envelope.responseCode)
        }
        // The server rotates both tokens on reissue.
        try tokenStore.save(
            TokenPair(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
        )
    }
}
