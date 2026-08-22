import CoreAuth
import CoreNetwork
import Foundation
import Testing

struct AuthenticatedNetworkClientTests {
    private let backing = InMemoryKeyValueStore()
    private var tokenStore: TokenStore { TokenStore(store: backing) }

    /// Real AuthSessionManager + scripted network — the master-prompt test
    /// scenario ("stub NetworkClient, 401→refresh→retry chain") end to end.
    /// The scripted client serves both roles: the decorator's base transport
    /// and the manager's reissue transport.
    private func makeSUT(
        handler: @escaping @Sendable (any Endpoint, Int) async throws -> Data,
        issuer: StubIssuer = StubIssuer(result: .failure(AuthError.issuerNotConfigured)),
        publicPathSuffixes: [String] = ["/auth/reissue"]
    ) -> (sut: AuthenticatedNetworkClient, network: ScriptedNetworkClient, issuer: StubIssuer) {
        let network = ScriptedNetworkClient(handler: handler)
        let manager = AuthSessionManager(tokenStore: tokenStore, networkClient: network, issuer: issuer)
        let sut = AuthenticatedNetworkClient(
            base: network,
            sessionManager: manager,
            publicPathSuffixes: publicPathSuffixes
        )
        return (sut, network, issuer)
    }

    @Test
    func dataFor_withStoredAccessToken_attachesBearerHeader() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (sut, network, _) = makeSUT(handler: { _, _ in Data("ok".utf8) })

        let result = try await sut.data(for: TestEndpoint())

        #expect(result == Data("ok".utf8))
        #expect(network.recorded.first?.headers["Authorization"] == "Bearer A")
    }

    @Test
    func dataFor_withoutToken_sendsWithoutAuthorizationHeader() async throws {
        let (sut, network, _) = makeSUT(handler: { _, _ in Data() })

        _ = try await sut.data(for: TestEndpoint())

        #expect(network.recorded.first?.headers["Authorization"] == nil)
    }

    @Test
    func dataFor_publicPathSuffix_skipsAuthorizationHeader() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (sut, network, _) = makeSUT(
            handler: { _, _ in Data() },
            publicPathSuffixes: ["/public/thing"]
        )

        _ = try await sut.data(for: TestEndpoint(path: "/api/public/thing"))

        #expect(network.recorded.first?.headers["Authorization"] == nil)
    }

    @Test
    func dataFor_on401_refreshesAndRetriesWithNewToken() async throws {
        try tokenStore.save(TokenPair(accessToken: "OLD", refreshToken: "R"))
        let (sut, network, _) = makeSUT(handler: { endpoint, index in
            switch (endpoint.path, index) {
            case ("/things", 0): throw unauthorizedError()
            case ("/things", _): return Data("ok".utf8)
            default: return reissueSuccessBody(access: "NEW", refresh: "R2")
            }
        })

        let result = try await sut.data(for: TestEndpoint())

        #expect(result == Data("ok".utf8))
        #expect(network.recordedCalls(to: "/auth/reissue").count == 1)
        let sends = network.recordedCalls(to: "/things")
        #expect(sends.count == 2)
        #expect(sends.last?.headers["Authorization"] == "Bearer NEW")
    }

    @Test
    func dataFor_on401RetryAlso401_throwsWithoutSecondRefresh() async throws {
        try tokenStore.save(TokenPair(accessToken: "OLD", refreshToken: "R"))
        let (sut, network, _) = makeSUT(handler: { endpoint, _ in
            if endpoint.path == "/things" { throw unauthorizedError() }
            return reissueSuccessBody(access: "NEW", refresh: "R2")
        })

        await #expect(throws: NetworkError.self) {
            try await sut.data(for: TestEndpoint())
        }

        #expect(network.recordedCalls(to: "/things").count == 2)
        #expect(network.recordedCalls(to: "/auth/reissue").count == 1)
    }

    /// Recovery failure surfaces the *original* 401 (NetworkClient contract),
    /// not the internal auth error, and skips the unauthenticated retry.
    @Test
    func dataFor_on401RecoveryFails_rethrowsOriginalUnauthorized() async throws {
        let marker = Data("original-401".utf8)
        let (sut, network, _) = makeSUT(handler: { _, _ in
            throw NetworkError.unacceptableStatus(code: 401, data: marker)
        })

        do {
            _ = try await sut.data(for: TestEndpoint())
            Issue.record("Expected the original 401 to be rethrown")
        } catch let error as NetworkError {
            guard case .unacceptableStatus(code: 401, data: let data) = error else {
                Issue.record("Expected unacceptableStatus(401), got \(error)")
                return
            }
            #expect(data == marker)
        }

        #expect(network.recordedCalls(to: "/things").count == 1)
    }

    @Test
    func dataFor_401RefreshFailsIssuerSucceeds_retriesWithIssuedToken() async throws {
        try tokenStore.save(TokenPair(accessToken: "OLD", refreshToken: "DEAD"))
        let issued = TokenPair(accessToken: "ISSUED", refreshToken: "R2")
        let (sut, network, issuer) = makeSUT(
            handler: { endpoint, index in
                switch (endpoint.path, index) {
                case ("/things", 0): throw unauthorizedError()
                case ("/things", _): return Data("ok".utf8)
                default: throw unauthorizedError() // reissue rejected — refresh is dead
                }
            },
            issuer: StubIssuer(result: .success(issued))
        )

        let result = try await sut.data(for: TestEndpoint())

        #expect(result == Data("ok".utf8))
        #expect(issuer.issueCallCount == 1)
        #expect(network.recordedCalls(to: "/things").last?.headers["Authorization"] == "Bearer ISSUED")
    }

    @Test
    func dataFor_non401Status_propagatesWithoutRecovery() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (sut, network, _) = makeSUT(handler: { _, _ in
            throw NetworkError.unacceptableStatus(code: 500, data: Data())
        })

        await #expect(throws: NetworkError.self) {
            try await sut.data(for: TestEndpoint())
        }

        #expect(network.recordedCalls(to: "/things").count == 1)
        #expect(network.recordedCalls(to: "/auth/reissue").isEmpty)
    }

    @Test
    func request_on401_refreshesRetriesAndDecodes() async throws {
        struct Payload: Decodable, Equatable, Sendable {
            let value: String
        }
        try tokenStore.save(TokenPair(accessToken: "OLD", refreshToken: "R"))
        let (sut, network, _) = makeSUT(handler: { endpoint, index in
            switch (endpoint.path, index) {
            case ("/things", 0): throw unauthorizedError()
            case ("/things", _): return Data(#"{"value": "hi"}"#.utf8)
            default: return reissueSuccessBody(access: "NEW", refresh: "R2")
            }
        })

        let payload = try await sut.request(TestEndpoint(), as: Payload.self)

        #expect(payload == Payload(value: "hi"))
        #expect(network.recordedCalls(to: "/things").count == 2)
    }

    @Test
    func dataFor_endpointWithCustomHeaders_preservesThemAndAddsBearer() async throws {
        try tokenStore.save(TokenPair(accessToken: "A", refreshToken: "R"))
        let (sut, network, _) = makeSUT(handler: { _, _ in Data() })

        _ = try await sut.data(for: TestEndpoint(headers: ["X-Custom": "1"]))

        let headers = network.recorded.first?.headers
        #expect(headers?["X-Custom"] == "1")
        #expect(headers?["Authorization"] == "Bearer A")
    }

    /// Master prompt: "동시 다발 401에도 리프레시는 1회" — concurrent 401s share
    /// one recovery.
    @Test
    func dataFor_concurrent401s_triggersSingleRefresh() async throws {
        try tokenStore.save(TokenPair(accessToken: "OLD", refreshToken: "R"))
        let reissueReached = AsyncGate()
        let reissueRelease = AsyncGate()
        let (sut, network, _) = makeSUT(handler: { endpoint, _ in
            if endpoint.path == "/auth/reissue" {
                reissueReached.open()
                await reissueRelease.wait()
                return reissueSuccessBody(access: "NEW", refresh: "R2")
            }
            // Old token → 401; refreshed token → success.
            if endpoint.headers["Authorization"] == "Bearer OLD" { throw unauthorizedError() }
            return Data("ok".utf8)
        })

        async let first = sut.data(for: TestEndpoint())
        async let second = sut.data(for: TestEndpoint())
        async let third = sut.data(for: TestEndpoint())
        await reissueReached.wait()
        // The recovery is parked at the gate; give the remaining 401 callers
        // time to join it before releasing.
        try await Task.sleep(for: .milliseconds(50))
        reissueRelease.open()

        let results = try await [first, second, third]

        #expect(results.allSatisfy { $0 == Data("ok".utf8) })
        #expect(network.recordedCalls(to: "/auth/reissue").count == 1)
    }
}
