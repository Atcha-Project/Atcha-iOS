import Foundation
import os

/// 요청 단위 진단 로그(DEBUG 전용). 이 스택에는 인터셉터·로거가 없어서 실패가
/// 전부 같은 얼굴로 보였다 — base URL이 틀렸는지, 서버가 죽었는지, 디코딩이
/// 깨졌는지를 Console.app에서 한 줄로 가르기 위한 최소 계측이다.
/// Authorization 헤더와 본문은 절대 남기지 않는다(토큰이 실린다).
private let networkLogger = Logger(subsystem: "com.atcha.network", category: "request")

public struct URLSessionNetworkClient: NetworkClient {
    private let baseURL: URL
    private let session: URLSession
    // JSONDecoder is not Sendable — hand out a fresh instance per decode
    // through a @Sendable factory instead of sharing one.
    private let makeDecoder: @Sendable () -> JSONDecoder

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        makeDecoder: @escaping @Sendable () -> JSONDecoder = { JSONDecoder() }
    ) {
        self.baseURL = baseURL
        self.session = session
        self.makeDecoder = makeDecoder
    }

    public func data(for endpoint: any Endpoint) async throws -> Data {
        let request = try urlRequest(for: endpoint)
        do {
            return try await send(request)
        } catch let error as NetworkError {
            // 멱등 GET 1회 재시도(Phase 16) — transport 계열(타임아웃·연결 끊김)만.
            // offline은 즉시 재실패라 무의미, 취소는 사용자 의사, HTTP 상태·디코딩은
            // 전송 실패가 아니다. POST/DELETE는 이중 발사(알람 등록·해제) 위험으로 금지.
            guard endpoint.method == .get, case .transport(let underlying) = error,
                  (underlying as? URLError)?.code != .cancelled,
                  !(underlying is CancellationError)
            else { throw error }
            return try await send(request)
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        let started = ContinuousClock.now
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw Self.logging(NetworkError.classifyingTransport(error), request, started)
        }
        guard let http = response as? HTTPURLResponse else {
            throw Self.logging(NetworkError.invalidResponse, request, started)
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw Self.logging(
                NetworkError.unacceptableStatus(code: http.statusCode, data: data),
                request,
                started
            )
        }
        Self.logSuccess(request, status: http.statusCode, started: started)
        return data
    }

    /// 실패를 로그에 남기고 그대로 돌려준다 — 호출부의 `throw` 흐름을 바꾸지 않는다.
    private static func logging(
        _ error: NetworkError,
        _ request: URLRequest,
        _ started: ContinuousClock.Instant
    ) -> NetworkError {
        #if DEBUG
        networkLogger.error(
            """
            \(request.httpMethod ?? "?", privacy: .public) \
            \(request.url?.absoluteString ?? "?", privacy: .public) \
            → \(error.debugDescription, privacy: .public) \
            (\(Self.elapsedMilliseconds(since: started), privacy: .public)ms)
            """
        )
        #endif
        return error
    }

    private static func logSuccess(
        _ request: URLRequest,
        status: Int,
        started: ContinuousClock.Instant
    ) {
        #if DEBUG
        networkLogger.debug(
            """
            \(request.httpMethod ?? "?", privacy: .public) \
            \(request.url?.absoluteString ?? "?", privacy: .public) \
            → \(status, privacy: .public) \
            (\(Self.elapsedMilliseconds(since: started), privacy: .public)ms)
            """
        )
        #endif
    }

    private static func elapsedMilliseconds(since started: ContinuousClock.Instant) -> Int {
        Int((ContinuousClock.now - started) / .milliseconds(1))
    }

    public func request<Response: Decodable & Sendable>(
        _ endpoint: any Endpoint,
        as _: Response.Type
    ) async throws -> Response {
        let data = try await data(for: endpoint)
        do {
            return try makeDecoder().decode(Response.self, from: data)
        } catch {
            throw NetworkError.decoding(underlying: error)
        }
    }

    // internal, not private — exercised directly by unit tests.
    func urlRequest(for endpoint: any Endpoint) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        for (field, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
