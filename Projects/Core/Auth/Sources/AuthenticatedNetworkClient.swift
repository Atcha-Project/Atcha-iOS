import CoreNetwork
import Foundation

/// NetworkClient decorator that attaches the Bearer access token, and on a 401
/// runs the session-recovery chain once before a single retry. Wrap the plain
/// URLSessionNetworkClient with this at the composition root — callers keep
/// seeing the NetworkClient contract, so no Data/Feature code changes.
public struct AuthenticatedNetworkClient: NetworkClient {
    private let base: any NetworkClient
    private let sessionManager: AuthSessionManager
    /// Legacy allowlist semantics: suffix match on the request path skips the
    /// Authorization header entirely.
    private let publicPathSuffixes: [String]

    public init(
        base: any NetworkClient,
        sessionManager: AuthSessionManager,
        publicPathSuffixes: [String] = ["/auth/reissue"]
    ) {
        self.base = base
        self.sessionManager = sessionManager
        self.publicPathSuffixes = publicPathSuffixes
    }

    public func data(for endpoint: any Endpoint) async throws -> Data {
        try await perform(endpoint) { try await base.data(for: $0) }
    }

    public func request<Response: Decodable & Sendable>(
        _ endpoint: any Endpoint,
        as type: Response.Type
    ) async throws -> Response {
        try await perform(endpoint) { try await base.request($0, as: type) }
    }

    private func perform<Value: Sendable>(
        _ endpoint: any Endpoint,
        send: @Sendable (any Endpoint) async throws -> Value
    ) async throws -> Value {
        if publicPathSuffixes.contains(where: { endpoint.path.hasSuffix($0) }) {
            return try await send(endpoint)
        }
        do {
            return try await send(authorized(endpoint))
        } catch let networkError as NetworkError {
            guard case .unacceptableStatus(code: 401, data: _) = networkError else {
                throw networkError
            }
            do {
                try await sessionManager.recoverSession()
            } catch {
                // Recovery is impossible — surface the original 401 so callers
                // keep receiving the NetworkError contract, and skip the
                // pointless unauthenticated retry (legacy doNotRetry).
                throw networkError
            }
            // Single retry; a second 401 propagates as-is.
            return try await send(authorized(endpoint))
        }
    }

    /// No token (or an unreadable keychain) degrades to an unauthenticated
    /// request — legacy semantics: never block the request itself.
    private func authorized(_ endpoint: any Endpoint) -> any Endpoint {
        guard let token = try? sessionManager.tokenStore.accessToken() else {
            return endpoint
        }
        return AuthorizedEndpoint(base: endpoint, accessToken: token)
    }
}

/// Endpoint has no auth flag, so authorization is layered on by wrapping: all
/// members delegate to the base and only headers gain the Bearer entry
/// (overwriting on conflict, like the legacy interceptor's setValue).
struct AuthorizedEndpoint: Endpoint {
    let base: any Endpoint
    let accessToken: String

    var path: String { base.path }
    var method: HTTPMethod { base.method }
    var queryItems: [URLQueryItem] { base.queryItems }
    var body: Data? { base.body }
    var headers: [String: String] {
        base.headers.merging(["Authorization": "Bearer \(accessToken)"]) { _, bearer in bearer }
    }
}
