import Foundation

public extension KeyValueStore {
    /// 부재 → nil. 저장된 데이터가 디코딩 불가면 throw (숨기지 않는다 — 무시 정책은 호출자 몫).
    // JSONDecoder/JSONEncoder는 non-Sendable — 공유하지 않고 호출마다 새로 만든다.
    func value<T: Decodable>(_ type: T.Type = T.self, forKey key: String) throws -> T? {
        guard let data = try data(forKey: key) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func setValue<T: Encodable>(_ value: T, forKey key: String) throws {
        try set(JSONEncoder().encode(value), forKey: key)
    }
}
