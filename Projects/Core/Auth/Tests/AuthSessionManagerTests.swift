import CoreAuth
import CoreNetwork
import Foundation
import Testing

struct AuthSessionManagerTests {
    private let backing = InMemoryKeyValueStore()
    private var tokenStore: TokenStore { TokenStore(store: backing) }

    private func makeManager(
        handler: @escaping @Sendable (any Endpoint, Int) async throws -> Data = { _, _ in Data() }
    ) -> (manager: AuthSessionManager, network: ScriptedNetworkClient) {
        let network = ScriptedNetworkClient(handler: handler)
        let manager = AuthSessionManager(tokenStore: tokenStore, networkClient: network)
        return (manager, network)
    }

    // MARK: - bootstrapState

    @Test
    func bootstrapState_emptyStore_returnsLoginRequired() {
        let (manager, _) = makeManager()

        #expect(manager.bootstrapState() == .loginRequired)
    }

    @Test
    func bootstrapState_existingAccessToken_returnsActive() throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (manager, _) = makeManager()

        #expect(manager.bootstrapState() == .active)
    }

    // MARK: - adopt / clearSession

    @Test
    func adopt_savesBothTokens() async throws {
        let (manager, _) = makeManager()

        try await manager.adopt(TokenPair(accessToken: "A", refreshToken: "R"))

        #expect(try tokenStore.accessToken() == "A")
        #expect(try tokenStore.refreshToken() == "R")
        #expect(manager.bootstrapState() == .active)
    }

    @Test
    func clearSession_removesTokens() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (manager, _) = makeManager()

        try await manager.clearSession()

        #expect(try tokenStore.accessToken() == nil)
        #expect(manager.bootstrapState() == .loginRequired)
    }

    // MARK: - recoverSession

    /// Pins the legacy-measured reissue contract: GET /auth/reissue with the
    /// refresh token as the Bearer credential.
    @Test
    func recoverSession_withRefreshToken_sendsGetReissueWithBearerRefreshHeader() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (manager, network) = makeManager(handler: { _, _ in
            reissueSuccessBody(access: "A2", refresh: "R2")
        })

        try await manager.recoverSession()

        let reissues = network.recordedCalls(to: "/auth/reissue")
        #expect(reissues.count == 1)
        #expect(reissues.first?.method == .get)
        #expect(reissues.first?.headers["Authorization"] == "Bearer R")
    }

    @Test
    func recoverSession_reissueSuccess_rotatesBothTokens() async throws {
        try tokenStore.save(TokenPair(accessToken: "A1", refreshToken: "R1"))
        let (manager, _) = makeManager(handler: { _, _ in
            reissueSuccessBody(access: "A2", refresh: "R2")
        })

        try await manager.recoverSession()

        #expect(try tokenStore.accessToken() == "A2")
        #expect(try tokenStore.refreshToken() == "R2")
    }

    /// A non-success envelope is a definitive rejection: the session is dead,
    /// tokens are cleared, and the caller gets `loginRequired`.
    @Test
    func recoverSession_reissueNonSuccessCode_clearsTokensAndThrowsLoginRequired() async throws {
        try tokenStore.save(TokenPair(accessToken: "A1", refreshToken: "R1"))
        let (manager, _) = makeManager(handler: { _, _ in
            reissueRejectedBody(responseCode: "AUTH_401")
        })

        await #expect(throws: AuthError.loginRequired) {
            try await manager.recoverSession()
        }

        #expect(try tokenStore.accessToken() == nil)
        #expect(try tokenStore.refreshToken() == nil)
    }

    @Test
    func recoverSession_reissueHTTP401_clearsTokensAndThrowsLoginRequired() async throws {
        try tokenStore.save(TokenPair(accessToken: "A1", refreshToken: "R1"))
        let (manager, _) = makeManager(handler: { _, _ in throw unauthorizedError() })

        await #expect(throws: AuthError.loginRequired) {
            try await manager.recoverSession()
        }

        #expect(try tokenStore.accessToken() == nil)
    }

    @Test
    func recoverSession_noRefreshToken_throwsLoginRequiredWithoutReissue() async throws {
        let (manager, network) = makeManager()

        await #expect(throws: AuthError.loginRequired) {
            try await manager.recoverSession()
        }

        #expect(network.recorded.isEmpty)
    }

    /// A definitive rejection notifies the expiry stream (buffered — the
    /// subscriber may attach later).
    @Test
    func recoverSession_definitiveRejection_yieldsSessionExpired() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (manager, _) = makeManager(handler: { _, _ in throw unauthorizedError() })

        await #expect(throws: AuthError.loginRequired) {
            try await manager.recoverSession()
        }

        var iterator = manager.sessionExpired.makeAsyncIterator()
        #expect(await iterator.next() != nil)
    }

    /// Transient failures (offline etc.) are not a logout: tokens survive and
    /// the error propagates untouched so callers treat it as a network error.
    @Test
    func recoverSession_transientFailure_keepsTokensAndPropagates() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (manager, _) = makeManager(handler: { _, _ in
            throw NetworkError.offline(underlying: URLError(.notConnectedToInternet))
        })

        await #expect(throws: NetworkError.self) {
            try await manager.recoverSession()
        }

        #expect(try tokenStore.accessToken() == "A")
        #expect(try tokenStore.refreshToken() == "R")
    }

    @Test
    func recoverSession_reissueHTTP500_keepsTokensAndPropagates() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (manager, _) = makeManager(handler: { _, _ in
            throw NetworkError.unacceptableStatus(code: 500, data: Data())
        })

        await #expect(throws: NetworkError.self) {
            try await manager.recoverSession()
        }

        #expect(try tokenStore.accessToken() == "A")
    }

    /// Single-flight: while one recovery is parked mid-reissue, concurrent
    /// callers join it instead of starting their own.
    @Test
    func recoverSession_concurrentCalls_performsSingleReissue() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let reissueReached = AsyncGate()
        let reissueRelease = AsyncGate()
        let (manager, network) = makeManager(handler: { _, _ in
            reissueReached.open()
            await reissueRelease.wait()
            return reissueSuccessBody(access: "A2", refresh: "R2")
        })

        async let first: Void = manager.recoverSession()
        await reissueReached.wait()
        async let second: Void = manager.recoverSession()
        async let third: Void = manager.recoverSession()
        // The recovery task stays registered until the gate opens; give the
        // joiners ample time to enter the actor before releasing.
        try await Task.sleep(for: .milliseconds(50))
        reissueRelease.open()

        _ = try await (first, second, third)

        #expect(network.recordedCalls(to: "/auth/reissue").count == 1)
        #expect(try tokenStore.accessToken() == "A2")
    }

    @Test
    func recoverSession_sequentialCalls_performsReissuePerCall() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (manager, network) = makeManager(handler: { _, index in
            reissueSuccessBody(access: "A\(index + 2)", refresh: "R\(index + 2)")
        })

        try await manager.recoverSession()
        try await manager.recoverSession()

        #expect(network.recordedCalls(to: "/auth/reissue").count == 2)
        #expect(try tokenStore.accessToken() == "A3")
    }
}
