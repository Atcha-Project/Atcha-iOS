@testable import CoreNetwork
import Foundation
import Testing

private struct GetEndpoint: Endpoint {
    let path = "/ping"
    let method: HTTPMethod = .get
}

private struct PostEndpoint: Endpoint {
    let path = "/register"
    let method: HTTPMethod = .post
}

/// URLProtocol 스텁 — 응답 큐를 순서대로 소비한다. static 상태를 쓰므로
/// 이 스텁을 쓰는 테스트 스위트는 `.serialized`여야 한다.
private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) private static var queue: [Result<(status: Int, data: Data), URLError>] = []
    nonisolated(unsafe) private(set) static var requestCount = 0
    private static let lock = NSLock()

    static func reset(queue newQueue: [Result<(status: Int, data: Data), URLError>]) {
        lock.lock()
        defer { lock.unlock() }
        queue = newQueue
        requestCount = 0
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        Self.lock.lock()
        Self.requestCount += 1
        let next = Self.queue.isEmpty ? nil : Self.queue.removeFirst()
        Self.lock.unlock()

        switch next {
        case let .success((status, data)):
            let response = HTTPURLResponse(
                url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
        }
    }
}

private func makeClient() -> URLSessionNetworkClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return URLSessionNetworkClient(
        baseURL: URL(string: "https://api.example.com")!,
        session: URLSession(configuration: configuration)
    )
}

@Suite(.serialized)
struct URLSessionNetworkClientRetryTests {
    @Test
    func get_transportFailureThenSuccess_retriesOnce() async throws {
        StubURLProtocol.reset(queue: [
            .failure(URLError(.timedOut)),
            .success((status: 200, data: Data("ok".utf8))),
        ])
        let data = try await makeClient().data(for: GetEndpoint())
        #expect(data == Data("ok".utf8))
        #expect(StubURLProtocol.requestCount == 2)
    }

    @Test
    func get_transportFailureTwice_throwsAfterSingleRetry() async {
        StubURLProtocol.reset(queue: [
            .failure(URLError(.networkConnectionLost)),
            .failure(URLError(.networkConnectionLost)),
        ])
        await #expect(throws: NetworkError.self) {
            try await makeClient().data(for: GetEndpoint())
        }
        // 1회 재시도까지만 — 무한 재시도 금지.
        #expect(StubURLProtocol.requestCount == 2)
    }

    @Test
    func get_offline_throwsOfflineWithoutRetry() async {
        StubURLProtocol.reset(queue: [
            .failure(URLError(.notConnectedToInternet)),
            .success((status: 200, data: Data())),
        ])
        do {
            _ = try await makeClient().data(for: GetEndpoint())
            Issue.record("offline인데 성공했다")
        } catch let error as NetworkError {
            #expect(error.isOffline)
        } catch {
            Issue.record("NetworkError가 아닌 에러: \(error)")
        }
        // 연결 자체가 없으면 즉시 재실패라 재시도하지 않는다.
        #expect(StubURLProtocol.requestCount == 1)
    }

    @Test
    func post_transportFailure_doesNotRetry() async {
        StubURLProtocol.reset(queue: [
            .failure(URLError(.timedOut)),
            .success((status: 200, data: Data())),
        ])
        await #expect(throws: NetworkError.self) {
            try await makeClient().data(for: PostEndpoint())
        }
        // 비멱등(알람 등록 등)은 이중 발사 위험 — 재시도 금지.
        #expect(StubURLProtocol.requestCount == 1)
    }

    @Test
    func get_httpErrorStatus_doesNotRetry() async {
        StubURLProtocol.reset(queue: [
            .success((status: 500, data: Data())),
            .success((status: 200, data: Data())),
        ])
        await #expect(throws: NetworkError.self) {
            try await makeClient().data(for: GetEndpoint())
        }
        // 재시도 대상은 transport 계열뿐 — HTTP 상태 실패는 그대로 던진다.
        #expect(StubURLProtocol.requestCount == 1)
    }
}

struct NetworkErrorClassificationTests {
    @Test
    func classifyingTransport_offlineCodes() {
        #expect(NetworkError.classifyingTransport(URLError(.notConnectedToInternet)).isOffline)
        #expect(NetworkError.classifyingTransport(URLError(.dataNotAllowed)).isOffline)
    }

    @Test
    func classifyingTransport_transientCodesStayTransport() {
        // 연결 끊김·타임아웃은 일시 장애 — 재시도로 살린다(offline 아님).
        #expect(!NetworkError.classifyingTransport(URLError(.networkConnectionLost)).isOffline)
        #expect(!NetworkError.classifyingTransport(URLError(.timedOut)).isOffline)
        #expect(!NetworkError.classifyingTransport(URLError(.cancelled)).isOffline)
    }
}
