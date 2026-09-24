import CoreNetwork

/// Whether a stored session exists at launch. The splash decides between the
/// home flow (`active`) and the login flow (`loginRequired`) on this alone —
/// token validity is proven lazily by the first authenticated request.
public enum SessionState: Sendable, Equatable {
    case active
    case loginRequired
}

/// Owns the session lifecycle: adopting server tokens after social login,
/// token refresh via GET /auth/reissue, and the 401-recovery chain.
/// Single-flight is guaranteed by keeping the in-progress recovery task on
/// the actor — the legacy interceptor's waiting-queue semantics without the
/// queue.
public actor AuthSessionManager {
    /// Read synchronously by the decorator on every request (no actor hop);
    /// TokenStore is a Sendable value and the keychain store locks internally.
    public nonisolated let tokenStore: TokenStore

    /// Yields once each time the session dies for good (no refresh token, or
    /// the server rejected the refresh). Single-consumer stream — the app
    /// coordinator subscribes and routes back to login; yields are buffered
    /// until consumed.
    public nonisolated let sessionExpired: AsyncStream<Void>

    /// Must be the plain (undecorated) client — the legacy setup used a
    /// separate interceptor-free session for reissue to break recursion.
    private let networkClient: any NetworkClient
    private let expiryContinuation: AsyncStream<Void>.Continuation
    private var recoveryTask: Task<Void, any Error>?

    public init(tokenStore: TokenStore, networkClient: any NetworkClient) {
        self.tokenStore = tokenStore
        self.networkClient = networkClient
        (sessionExpired, expiryContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    /// Splash-time check: no network, no throw — a keychain read failure just
    /// means there is no usable session.
    public nonisolated func bootstrapState() -> SessionState {
        ((try? tokenStore.accessToken()) != nil) ? .active : .loginRequired
    }

    /// Adopts the server token pair obtained by social login. Actor-isolated
    /// so adoption serializes with any in-flight recovery.
    public func adopt(_ tokens: TokenPair) throws {
        try tokenStore.save(tokens)
    }

    /// Logout/withdrawal path (screens are a later phase — the clear path
    /// ships now so callers never reach into TokenStore directly).
    public func clearSession() throws {
        try tokenStore.clear()
    }

    /// Logout: best-effort server call (legacy special case — the *refresh*
    /// token rides as Bearer), then local expiry either way. Offline or a
    /// server failure must never trap the user in a session they asked to end.
    public func signOut() async {
        if let refreshToken = try? tokenStore.refreshToken() {
            _ = try? await networkClient.data(for: LogoutEndpoint(refreshToken: refreshToken))
        }
        _ = expireSession()
    }

    /// Post-withdrawal cleanup: the server already revoked the tokens, so no
    /// network call — just local expiry and the login-routing yield.
    public func invalidateSession() {
        _ = expireSession()
    }

    /// Single entry point for 401 recovery: refresh, or declare the session
    /// dead (`AuthError.loginRequired` + a `sessionExpired` yield). Concurrent
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
        guard let refreshToken = try? tokenStore.refreshToken() else {
            throw expireSession()
        }
        do {
            try await refreshTokens(with: refreshToken)
        } catch {
            // Only a definitive server rejection kills the session. Transient
            // failures (offline, 5xx, decoding) propagate untouched so the
            // caller treats them as network errors — never as a logout.
            guard isDefinitiveRejection(error) else { throw error }
            throw expireSession()
        }
    }

    /// Best-effort clear (a keychain failure must not mask the expiry),
    /// notify the observer, and hand back the error to throw.
    private func expireSession() -> AuthError {
        try? tokenStore.clear()
        expiryContinuation.yield()
        return .loginRequired
    }

    private func isDefinitiveRejection(_ error: any Error) -> Bool {
        if error is AuthError { return true }
        if case NetworkError.unacceptableStatus(code: 401, data: _) = error { return true }
        return false
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
