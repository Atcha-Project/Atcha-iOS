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
    
    private let accessTokenKey: KeychainWrapper.Key = "accessToken"
    private let refreshTokenKey: KeychainWrapper.Key = "refreshToken"
    private let fcmTokenKey: KeychainWrapper.Key = "fcmToken"
    
    var accessToken: String? {
        get { keychain.string(forKey: accessTokenKey.rawValue) }
        set {
            if let token = newValue {
                keychain.set(token, forKey: accessTokenKey.rawValue)
            } else {
                keychain.remove(forKey: accessTokenKey.rawValue)
            }
        }
    }
    
    var refreshToken: String? {
        get { keychain.string(forKey: refreshTokenKey.rawValue) }
        set {
            if let token = newValue {
                keychain.set(token, forKey: refreshTokenKey.rawValue)
            } else {
                keychain.remove(forKey: refreshTokenKey.rawValue)
            }
        }
    }
    
    var fcmToken: String? {
        get { keychain.string(forKey: fcmTokenKey.rawValue) }
        set {
            if let token = newValue {
                keychain.set(token, forKey: fcmTokenKey.rawValue)
            } else {
                keychain.remove(forKey: fcmTokenKey.rawValue)
            }
        }
    }
}

// MARK: - Delete
extension TokenStorageImpl {
    func clearAllTokens() {
        keychain.remove(forKey: accessTokenKey.rawValue)
        keychain.remove(forKey: refreshTokenKey.rawValue)
//        keychain.remove(forKey: fcmTokenKey.rawValue)
    }
    
    func clearAccessToken() {
        keychain.remove(forKey: accessTokenKey.rawValue)
    }
    
    func clearRefreshToken() {
        keychain.remove(forKey: refreshTokenKey.rawValue)
    }
    
    func clearFCMToken() {
        keychain.remove(forKey: fcmTokenKey.rawValue)
    }
}

// MARK: - Update
extension TokenStorageImpl {
    func updateAccessToken(_ token: String) {
        keychain.set(token, forKey: accessTokenKey.rawValue)
    }
    
    func updateRefreshToken(_ token: String) {
        keychain.set(token, forKey: refreshTokenKey.rawValue)
    }
    
    func updateFCMToken(_ token: String) {
        keychain.set(token, forKey: fcmTokenKey.rawValue)
    }
}

// MARK: - Check
extension TokenStorageImpl {
    func hasAccessToken() -> Bool {
        return keychain.string(forKey: accessTokenKey.rawValue) != nil
    }
    
    func hasRefreshToken() -> Bool {
        return keychain.string(forKey: refreshTokenKey.rawValue) != nil
    }
    
    func hasFCMToken() -> Bool {
        return keychain.string(forKey: fcmTokenKey.rawValue) != nil
    }
}
