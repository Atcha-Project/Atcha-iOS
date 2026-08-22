import Foundation

// UserDefaults는 문서화된 thread-safe지만 SDK가 Sendable로 표기하지 않아 @unchecked가 필요하다.
public final class UserDefaultsKeyValueStore: KeyValueStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func data(forKey key: String) throws -> Data? {
        defaults.data(forKey: key)
    }

    public func set(_ data: Data, forKey key: String) throws {
        defaults.set(data, forKey: key)
    }

    public func removeValue(forKey key: String) throws {
        defaults.removeObject(forKey: key)
    }
}
