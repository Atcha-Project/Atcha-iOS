import Foundation

public protocol NetworkClient: Sendable {
    func data(for endpoint: any Endpoint) async throws -> Data
    func request<Response: Decodable & Sendable>(
        _ endpoint: any Endpoint,
        as type: Response.Type
    ) async throws -> Response
}

public extension NetworkClient {
    func request<Response: Decodable & Sendable>(
        _ endpoint: any Endpoint
    ) async throws -> Response {
        try await request(endpoint, as: Response.self)
    }
}
