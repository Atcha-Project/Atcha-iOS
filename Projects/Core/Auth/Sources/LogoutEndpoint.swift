import CoreNetwork

/// Legacy-measured contract (TokenInterceptor special case): POST /auth/logout
/// with the *refresh* token as the Bearer credential — the reason this endpoint
/// lives in CoreAuth instead of AtchaData, which has no token access.
struct LogoutEndpoint: Endpoint {
    let refreshToken: String

    var path: String { "/auth/logout" }
    var method: HTTPMethod { .post }
    var headers: [String: String] { ["Authorization": "Bearer \(refreshToken)"] }
}
