public struct TokenPair: Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

/// Issues a brand-new anonymous session (first launch, or when refresh is no
/// longer possible). The real endpoint spec is pending (미확정 입력 #2); once it
/// lands, add a concrete implementation and swap it in AppDIContainer — no
/// other CoreAuth code changes.
public protocol AnonymousSessionIssuing: Sendable {
    func issueSession() async throws -> TokenPair
}

/// Stand-in until the issuance endpoint spec is confirmed: always throws
/// `AuthError.issuerNotConfigured`.
public struct UnconfiguredAnonymousSessionIssuer: AnonymousSessionIssuing {
    public init() {}

    public func issueSession() async throws -> TokenPair {
        throw AuthError.issuerNotConfigured
    }
}
