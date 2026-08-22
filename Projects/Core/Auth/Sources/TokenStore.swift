import CoreStorage
import Foundation

/// Keeps the session tokens under the legacy key names ("accessToken" /
/// "refreshToken") as raw UTF-8. The backing store is the v2 keychain service,
/// so there is no legacy migration concern — the names are kept only so the
/// stored contract stays recognizable.
public struct TokenStore: Sendable {
    private enum Key {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    private let store: any KeyValueStore

    public init(store: any KeyValueStore) {
        self.store = store
    }

    public func accessToken() throws -> String? {
        try string(forKey: Key.accessToken)
    }

    public func refreshToken() throws -> String? {
        try string(forKey: Key.refreshToken)
    }

    /// Saves both tokens — the server rotates the refresh token on reissue, so
    /// a pair is always written together.
    public func save(_ pair: TokenPair) throws {
        try store.set(Data(pair.accessToken.utf8), forKey: Key.accessToken)
        try store.set(Data(pair.refreshToken.utf8), forKey: Key.refreshToken)
    }

    public func clear() throws {
        try store.removeValue(forKey: Key.accessToken)
        try store.removeValue(forKey: Key.refreshToken)
    }

    private func string(forKey key: String) throws -> String? {
        guard let data = try store.data(forKey: key) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }
}
