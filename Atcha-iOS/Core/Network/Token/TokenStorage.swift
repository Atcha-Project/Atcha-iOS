//
//  TokenStorage.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation

protocol TokenStorage {
    var accessToken: String? { get set }
    var refreshToken: String? { get set }
    var fcmToken: String? { get set }
    
    func clearAllTokens()
    func clearAccessToken()
    func clearRefreshToken()
    func clearFCMToken()
    
    func updateAccessToken(_ token: String)
    func updateRefreshToken(_ token: String)
    func updateFCMToken(_ token: String)
    
    func hasAccessToken() -> Bool
    func hasRefreshToken() -> Bool
    func hasFCMToken() -> Bool
}

final class TokenStorageImpl: TokenStorage {
    private let keychain = KeychainWrapper()
    private var cachedAccessToken: String?
        private var cachedRefreshToken: String?
        private var cachedFCMToken: String?
    
    private let accessTokenKey: KeychainWrapper.Key = "accessToken"
    private let refreshTokenKey: KeychainWrapper.Key = "refreshToken"
    private let fcmTokenKey: KeychainWrapper.Key = "fcmToken"
    
    var accessToken: String? {
            get {
                if let cached = cachedAccessToken { return cached }
                let token = keychain.string(forKey: accessTokenKey.rawValue)
                cachedAccessToken = token
                return token
            }
            set {
                cachedAccessToken = newValue
                if let token = newValue { keychain.set(token, forKey: accessTokenKey.rawValue) }
                else { keychain.remove(forKey: accessTokenKey.rawValue) }
            }
        }
        
        var refreshToken: String? {
            get {
                if let cached = cachedRefreshToken { return cached }
                let token = keychain.string(forKey: refreshTokenKey.rawValue)
                cachedRefreshToken = token
                return token
            }
            set {
                cachedRefreshToken = newValue
                if let token = newValue { keychain.set(token, forKey: refreshTokenKey.rawValue) }
                else { keychain.remove(forKey: refreshTokenKey.rawValue) }
            }
        }
        
        var fcmToken: String? {
            get {
                if let cached = cachedFCMToken { return cached }
                let token = keychain.string(forKey: fcmTokenKey.rawValue)
                cachedFCMToken = token
                return token
            }
            set {
                cachedFCMToken = newValue
                if let token = newValue { keychain.set(token, forKey: fcmTokenKey.rawValue) }
                else { keychain.remove(forKey: fcmTokenKey.rawValue) }
            }
        }
}

// MARK: - Delete
extension TokenStorageImpl {
    // 프로퍼티 setter를 사용하면 캐시와 키체인이 동시에 지워집니다!
    func clearAllTokens() {
        self.accessToken = nil
        self.refreshToken = nil
        // self.fcmToken = nil // 기존 로직처럼 FCM 토큰은 유지
    }
    
    func clearAccessToken() {
        self.accessToken = nil
    }
    
    func clearRefreshToken() {
        self.refreshToken = nil
    }
    
    func clearFCMToken() {
        self.fcmToken = nil
    }
}

// MARK: - Update
extension TokenStorageImpl {
    // 프로퍼티 setter를 사용하면 캐시와 키체인이 동시에 업데이트됩니다!
    func updateAccessToken(_ token: String) {
        self.accessToken = token
    }
    
    func updateRefreshToken(_ token: String) {
        self.refreshToken = token
    }
    
    func updateFCMToken(_ token: String) {
        self.fcmToken = token
    }
}

// MARK: - Check
extension TokenStorageImpl {
    // 메모리 캐시까지 확인하도록 getter를 통과하게 만듭니다.
    func hasAccessToken() -> Bool {
        return self.accessToken != nil
    }
    
    func hasRefreshToken() -> Bool {
        return self.refreshToken != nil
    }
    
    func hasFCMToken() -> Bool {
        return self.fcmToken != nil
    }
}
