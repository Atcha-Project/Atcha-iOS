import CoreAuth
import CoreNetwork
import Foundation
import Testing

struct AuthSessionManagerTests {
    private let backing = InMemoryKeyValueStore()
    private var tokenStore: TokenStore { TokenStore(store: backing) }

    private func makeManager(
        handler: @escaping @Sendable (any Endpoint, Int) async throws -> Data = { _, _ in Data() },
        issuer: StubIssuer = StubIssuer(result: .failure(AuthError.issuerNotConfigured))
    ) -> (manager: AuthSessionManager, network: ScriptedNetworkClient, issuer: StubIssuer) {
        let network = ScriptedNetworkClient(handler: handler)
        let manager = AuthSessionManager(tokenStore: tokenStore, networkClient: network, issuer: issuer)
        return (manager, network, issuer)
    }

    // MARK: - bootstrap

    @Test
    func bootstrap_emptyStore_issuesAndSavesTokens() async throws {
        let issued = TokenPair(accessToken: "A", refreshToken: "R")
        let (manager, _, issuer) = makeManager(issuer: StubIssuer(result: .success(issued)))

        try await manager.bootstrap()

        #expect(issuer.issueCallCount == 1)
        #expect(try tokenStore.accessToken() == "A")
        #expect(try tokenStore.refreshToken() == "R")
    }

    @Test
    func bootstrap_existingAccessToken_skipsIssuer() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (manager, _, issuer) = makeManager()

        try await manager.bootstrap()

        #expect(issuer.issueCallCount == 0)
        #expect(try tokenStore.accessToken() == "A")
    }

    /// 미확정 입력 #2's interim behavior: an unconfigured issuer is non-fatal —
    /// the app proceeds without tokens.
    @Test
    func bootstrap_issuerNotConfigured_completesWithoutTokens() async throws {
        let (manager, _, _) = makeManager()

        try await manager.bootstrap()

        #expect(try tokenStore.accessToken() == nil)
    }

    @Test
    func bootstrap_issuerTransportFailure_throws() async {
        let (manager, _, _) = makeManager(
            issuer: StubIssuer(result: .failure(URLError(.notConnectedToInternet)))
        )

        await #expect(throws: URLError.self) {
            try await manager.bootstrap()
        }
    }

    // MARK: - recoverSession

    /// Pins the legacy-measured reissue contract: GET /auth/reissue with the
    /// refresh token as the Bearer credential.
    @Test
    func recoverSession_withRefreshToken_sendsGetReissueWithBearerRefreshHeader() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (manager, network, _) = makeManager(handler: { _, _ in
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
        let (manager, _, _) = makeManager(handler: { _, _ in
            reissueSuccessBody(access: "A2", refresh: "R2")
        })

        try await manager.recoverSession()

        #expect(try tokenStore.accessToken() == "A2")
        #expect(try tokenStore.refreshToken() == "R2")
    }

    @Test
    func recoverSession_reissueNonSuccessCode_fallsBackToIssuer() async throws {
        try tokenStore.save(TokenPair(accessToken: "A1", refreshToken: "R1"))
        let issued = TokenPair(accessToken: "A2", refreshToken: "R2")
        let (manager, _, issuer) = makeManager(
            handler: { _, _ in reissueRejectedBody(responseCode: "AUTH_401") },
            issuer: StubIssuer(result: .success(issued))
        )

        try await manager.recoverSession()

        #expect(issuer.issueCallCount == 1)
        #expect(try tokenStore.accessToken() == "A2")
    }

    @Test
    func recoverSession_reissueHTTP401_fallsBackToIssuer() async throws {
        try tokenStore.save(TokenPair(accessToken: "A1", refreshToken: "R1"))
        let issued = TokenPair(accessToken: "A2", refreshToken: "R2")
        let (manager, _, issuer) = makeManager(
            handler: { _, _ in throw unauthorizedError() },
            issuer: StubIssuer(result: .success(issued))
        )

        try await manager.recoverSession()

        #expect(issuer.issueCallCount == 1)
        #expect(try tokenStore.accessToken() == "A2")
    }

    @Test
    func recoverSession_noRefreshToken_skipsReissueAndUsesIssuer() async throws {
        let issued = TokenPair(accessToken: "A", refreshToken: "R")
        let (manager, network, issuer) = makeManager(issuer: StubIssuer(result: .success(issued)))

        try await manager.recoverSession()

        #expect(network.recorded.isEmpty)
        #expect(issuer.issueCallCount == 1)
        #expect(try tokenStore.accessToken() == "A")
    }

    @Test
    func recoverSession_refreshAndIssuerBothFail_throws() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (manager, _, _) = makeManager(
            handler: { _, _ in throw unauthorizedError() },
            issuer: StubIssuer(result: .failure(URLError(.notConnectedToInternet)))
        )

        await #expect(throws: URLError.self) {
            try await manager.recoverSession()
        }
    }

    /// Unlike bootstrap, recovery must not swallow issuerNotConfigured — the
    /// decorator needs the failure to rethrow the original 401.
    @Test
    func recoverSession_issuerNotConfigured_propagatesError() async {
        let (manager, _, _) = makeManager()

        await #expect(throws: AuthError.issuerNotConfigured) {
            try await manager.recoverSession()
        }
    }

    /// No destructive clearing: a failed recovery keeps the stored identity.
    @Test
    func recoverSession_reissueFailure_keepsExistingTokensWhenIssuerAlsoFails() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (manager, _, _) = makeManager(handler: { _, _ in throw unauthorizedError() })

        await #expect(throws: AuthError.issuerNotConfigured) {
            try await manager.recoverSession()
        }

        #expect(try tokenStore.accessToken() == "A")
        #expect(try tokenStore.refreshToken() == "R")
    }

    /// Single-flight: while one recovery is parked mid-reissue, concurrent
    /// callers join it instead of starting their own.
    @Test
    func recoverSession_concurrentCalls_performsSingleReissue() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let reissueReached = AsyncGate()
        let reissueRelease = AsyncGate()
        let (manager, network, _) = makeManager(handler: { _, _ in
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
        let (manager, network, _) = makeManager(handler: { _, index in
            reissueSuccessBody(access: "A\(index + 2)", refresh: "R\(index + 2)")
        })

        try await manager.recoverSession()
        try await manager.recoverSession()

        #expect(network.recordedCalls(to: "/auth/reissue").count == 2)
        #expect(try tokenStore.accessToken() == "A3")
    }
}
