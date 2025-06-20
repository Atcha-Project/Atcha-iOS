//
//  KeychainWrapper.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/20/25.
//

import Foundation
import Security

final public class KeychainWrapper {
    // MARK: - 저장
    public func set(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  key,
            kSecValueData as String:    data
        ]
        
        SecItemDelete(query as CFDictionary) // 기존 값 삭제 후 덮어쓰기
        SecItemAdd(query as CFDictionary, nil)
    }
    
    
    // MARK: - 불러오기
    public func string(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  key,
            kSecReturnData as String:   kCFBooleanTrue!,
            kSecMatchLimit as String:   kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }
    
    
    // MARK: - 삭제
    public func remove(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrAccount as String:  key
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    public func removeAll() {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    
    // MARK: - 키 정의 구조체
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
