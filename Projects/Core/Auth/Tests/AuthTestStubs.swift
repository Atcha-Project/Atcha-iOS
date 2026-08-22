import CoreAuth
import CoreNetwork
import CoreStorage
import Foundation
import Synchronization

// Shared within this test target only (single-target sharing — distinct from
// the intended Tests/Example duplication trade-off).

final class InMemoryKeyValueStore: KeyValueStore {
    private let storage = Mutex<[String: Data]>([:])

    func data(forKey key: String) throws -> Data? { storage.withLock { $0[key] } }
    func set(_ data: Data, forKey key: String) throws { storage.withLock { $0[key] = data } }
    func removeValue(forKey key: String) throws { storage.withLock { $0[key] = nil } }
}

/// Records every request and delegates the response to a scripted handler.
/// The handler receives the call index *among calls to the same path*, so
/// "first /things call fails, second succeeds" scripts stay readable.
final class ScriptedNetworkClient: NetworkClient {
    struct RecordedRequest: Sendable {
        let path: String
        let method: HTTPMethod
        let headers: [String: String]
    }

    private let handler: @Sendable (any Endpoint, Int) async throws -> Data
    private let recordedStorage = Mutex<[RecordedRequest]>([])

    init(handler: @escaping @Sendable (any Endpoint, Int) async throws -> Data) {
        self.handler = handler
    }

    var recorded: [RecordedRequest] { recordedStorage.withLock { $0 } }

    func recordedCalls(to path: String) -> [RecordedRequest] {
        recorded.filter { $0.path == path }
    }

    func data(for endpoint: any Endpoint) async throws -> Data {
        let pathCallIndex = recordedStorage.withLock { requests -> Int in
            let index = requests.count(where: { $0.path == endpoint.path })
            requests.append(RecordedRequest(
                path: endpoint.path,
                method: endpoint.method,
                headers: endpoint.headers
            ))
            return index
        }
        return try await handler(endpoint, pathCallIndex)
    }

    func request<Response: Decodable & Sendable>(
        _ endpoint: any Endpoint,
        as _: Response.Type
    ) async throws -> Response {
        try JSONDecoder().decode(Response.self, from: try await data(for: endpoint))
    }
}

final class StubIssuer: AnonymousSessionIssuing {
    private let result: Result<TokenPair, any Error>
    private let callCount = Mutex<Int>(0)

    init(result: Result<TokenPair, any Error>) {
        self.result = result
    }

    var issueCallCount: Int { callCount.withLock { $0 } }

    func issueSession() async throws -> TokenPair {
        callCount.withLock { $0 += 1 }
        return try result.get()
    }
}

/// Deterministic concurrency gate: `wait()` suspends until `open()`; once
/// opened, all current and future waiters pass immediately.
final class AsyncGate: Sendable {
    private struct State {
        var opened = false
        var waiters: [CheckedContinuation<Void, Never>] = []
    }

    private let state = Mutex<State>(State())

    func wait() async {
        await withCheckedContinuation { continuation in
            let passImmediately = state.withLock { state -> Bool in
                if state.opened { return true }
                state.waiters.append(continuation)
                return false
            }
            if passImmediately { continuation.resume() }
        }
    }

    func open() {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            state.opened = true
            let waiters = state.waiters
            state.waiters = []
            return waiters
        }
        for waiter in waiters { waiter.resume() }
    }
}

struct TestEndpoint: Endpoint {
    var path = "/things"
    var method: HTTPMethod = .get
    var headers: [String: String] = [:]
}

func reissueSuccessBody(access: String, refresh: String) -> Data {
    Data("""
    {"responseCode": "SUCCESS", "result": {"id": 1, "accessToken": "\(access)", "refreshToken": "\(refresh)"}}
    """.utf8)
}

func reissueRejectedBody(responseCode: String) -> Data {
    Data("""
    {"responseCode": "\(responseCode)", "result": null}
    """.utf8)
}

func unauthorizedError() -> NetworkError {
    .unacceptableStatus(code: 401, data: Data())
}
