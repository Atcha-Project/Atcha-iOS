import Foundation
import Security
import Synchronization

public enum KeychainError: Error, Equatable, Sendable {
    case unexpectedStatus(OSStatus)
}

/// 레거시 TokenStorage의 키체인+메모리 캐시 의미를 프로토콜 기반으로 재작성.
/// 캐시는 존재값만 보관하며 Mutex로 동기화한다 (레거시는 unsynchronized라 Swift 6 불가).
public final class KeychainStore: KeyValueStore {
    private let service: String
    private let cache = Mutex<[String: Data]>([:])

    public init(service: String = "com.atcha.iOS.v2") {
        self.service = service
    }

    public func data(forKey key: String) throws -> Data? {
        if let cached = cache.withLock({ $0[key] }) {
            return cached
        }
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { return nil }
            cache.withLock { $0[key] = data }
            return data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    public func set(_ data: Data, forKey key: String) throws {
        var addQuery = baseQuery(forKey: key)
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        // 레거시의 delete-then-add는 비원자적 — add 후 duplicate면 update로 대체한다.
        var status = SecItemAdd(addQuery as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let attributes: [String: Any] = [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            ]
            status = SecItemUpdate(baseQuery(forKey: key) as CFDictionary, attributes as CFDictionary)
        }
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        cache.withLock { $0[key] = data }
    }

    public func removeValue(forKey key: String) throws {
        let status = SecItemDelete(baseQuery(forKey: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
        cache.withLock { $0[key] = nil }
    }

    private func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
