public enum AuthError: Error, Equatable, Sendable {
    /// The session is definitively gone: no refresh token, or the server
    /// rejected the refresh. The user must sign in again — surfaced through
    /// `AuthSessionManager.sessionExpired` and thrown to the recovery caller.
    case loginRequired
    /// The reissue envelope came back with a non-success responseCode or an
    /// empty result.
    case refreshRejected(responseCode: String)
}
