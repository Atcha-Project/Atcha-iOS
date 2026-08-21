import Foundation

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
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.transport(underlying: error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw NetworkError.unacceptableStatus(code: http.statusCode, data: data)
        }
        return data
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
