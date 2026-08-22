import Foundation

/// Data 단위 key-value 저장 추상화. `nil` = 값 부재, `throw` = 실제 저장소 실패.
public protocol KeyValueStore: Sendable {
    func data(forKey key: String) throws -> Data?
    func set(_ data: Data, forKey key: String) throws
    func removeValue(forKey key: String) throws
}
