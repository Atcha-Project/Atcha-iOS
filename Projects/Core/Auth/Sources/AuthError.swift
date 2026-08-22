public enum AuthError: Error, Equatable, Sendable {
    /// The anonymous-session issuance endpoint spec is not confirmed yet
    /// (master prompt, 미확정 입력 #2). `bootstrap()` treats this as non-fatal;
    /// `recoverSession()` propagates it.
    case issuerNotConfigured
    /// The reissue envelope came back with a non-success responseCode or an
    /// empty result.
    case refreshRejected(responseCode: String)
}
