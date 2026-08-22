@testable import CoreStorage
import Foundation
import Synchronization
import Testing

private final class InMemoryKeyValueStore: KeyValueStore {
    private let storage = Mutex<[String: Data]>([:])

    func data(forKey key: String) throws -> Data? {
        storage.withLock { $0[key] }
    }

    func set(_ data: Data, forKey key: String) throws {
        storage.withLock { $0[key] = data }
    }

    func removeValue(forKey key: String) throws {
        storage.withLock { $0[key] = nil }
    }
}

private struct Token: Codable, Equatable {
    let value: String
    let expiresAt: Int
}

struct KeyValueStoreCodableTests {
    private let store = InMemoryKeyValueStore()

    @Test
    func setValue_thenValue_roundTripsCodable() throws {
        let token = Token(value: "abc", expiresAt: 123)
        try store.setValue(token, forKey: "token")
        #expect(try store.value(Token.self, forKey: "token") == token)
    }

    @Test
    func value_missingKey_returnsNil() throws {
        #expect(try store.value(Token.self, forKey: "missing") == nil)
    }

    @Test
    func value_corruptData_throwsDecodingError() throws {
        try store.set(Data("not json".utf8), forKey: "token")
        #expect(throws: DecodingError.self) {
            try store.value(Token.self, forKey: "token")
        }
    }

    @Test
    func setValue_overwrite_replacesPreviousValue() throws {
        try store.setValue(Token(value: "old", expiresAt: 1), forKey: "token")
        try store.setValue(Token(value: "new", expiresAt: 2), forKey: "token")
        #expect(try store.value(Token.self, forKey: "token") == Token(value: "new", expiresAt: 2))
    }

    @Test
    func removeValue_thenValue_returnsNil() throws {
        try store.setValue(Token(value: "abc", expiresAt: 1), forKey: "token")
        try store.removeValue(forKey: "token")
        #expect(try store.value(Token.self, forKey: "token") == nil)
    }
}
