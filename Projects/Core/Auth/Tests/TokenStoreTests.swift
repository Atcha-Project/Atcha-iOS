import CoreAuth
import Foundation
import Testing

struct TokenStoreTests {
    private let backing = InMemoryKeyValueStore()
    private var store: TokenStore { TokenStore(store: backing) }

    @Test
    func save_thenRead_returnsBothTokens() throws {
        try store.save(TokenPair(accessToken: "A", refreshToken: "R"))

        #expect(try store.accessToken() == "A")
        #expect(try store.refreshToken() == "R")
    }

    @Test
    func accessToken_emptyStore_returnsNil() throws {
        #expect(try store.accessToken() == nil)
        #expect(try store.refreshToken() == nil)
    }

    @Test
    func save_overwrite_rotatesBothTokens() throws {
        try store.save(TokenPair(accessToken: "A1", refreshToken: "R1"))
        try store.save(TokenPair(accessToken: "A2", refreshToken: "R2"))

        #expect(try store.accessToken() == "A2")
        #expect(try store.refreshToken() == "R2")
    }

    @Test
    func clear_thenRead_returnsNil() throws {
        try store.save(TokenPair(accessToken: "A", refreshToken: "R"))
        try store.clear()

        #expect(try store.accessToken() == nil)
        #expect(try store.refreshToken() == nil)
    }

    /// Pins the stored contract: legacy key names, raw UTF-8 values.
    @Test
    func save_usesLegacyKeychainKeys() throws {
        try store.save(TokenPair(accessToken: "A", refreshToken: "R"))

        #expect(try backing.data(forKey: "accessToken") == Data("A".utf8))
        #expect(try backing.data(forKey: "refreshToken") == Data("R".utf8))
    }
}
