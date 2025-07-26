//
//  UserDefaultsWrapper.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/20/25.
//

import Foundation

final public class UserDefaultsWrapper {
    
    private let userDefaults: UserDefaults = .standard
    
    
    // MARK: - 저장
    public func set(_ value: Int, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    public func set(_ value: Double, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    public func set(_ value: String, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    public func set(_ value: Bool, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    public func set(_ value: Data, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    public func set<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            userDefaults.set(data, forKey: key)
        }
    }
    
    
    // MARK: - 불러오기
    public func integer(forKey key: String) -> Int? {
        return userDefaults.value(forKey: key) as? Int
    }
    
    public func double(forKey key: String) -> Double? {
        return userDefaults.value(forKey: key) as? Double
    }
    
    public func string(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    public func bool(forKey key: String) -> Bool? {
        return userDefaults.value(forKey: key) as? Bool
    }
    
    public func data(forKey key: String) -> Data? {
        return userDefaults.data(forKey: key)
    }
    
    public func object<T: Decodable>(forKey key: String, of type: T.Type) -> T? {
        guard let data = userDefaults.data(forKey: key),
              let object = try? JSONDecoder().decode(type, from: data) else { return nil }
        return object
    }
    
    
    // MARK: - 삭제
    public func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    public func removeAll() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        userDefaults.removePersistentDomain(forName: bundleID)
    }
    
    // MARK: - 키 정의용 구조체
    public struct Key: Hashable, RawRepresentable, ExpressibleByStringLiteral {
        public var rawValue: String
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(stringLiteral value: StringLiteralType) {
            self.rawValue = value
        }
    }
}
