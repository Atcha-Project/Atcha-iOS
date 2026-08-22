import CoreNetwork

/// Legacy-measured contract: GET /auth/reissue with the *refresh* token as the
/// Bearer credential.
struct ReissueEndpoint: Endpoint {
    let refreshToken: String

    var path: String { "/auth/reissue" }
    var method: HTTPMethod { .get }
    var headers: [String: String] { ["Authorization": "Bearer \(refreshToken)"] }
}

/// Deliberate duplicate of AtchaData's APIResponse envelope — CoreAuth must
/// not import AtchaData, so it carries its own minimal decoding type.
struct ReissueEnvelope: Decodable, Sendable {
    let responseCode: String
    let result: Tokens?

    struct Tokens: Decodable, Sendable {
        let id: Int?
        let accessToken: String
        let refreshToken: String
    }
}
