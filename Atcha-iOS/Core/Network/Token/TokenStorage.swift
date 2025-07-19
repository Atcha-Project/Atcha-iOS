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

extension TokenStorageImpl {
    func clearAllTokens() {
        keychain.remove(forKey: accessTokenKey.rawValue)
        keychain.remove(forKey: refreshTokenKey.rawValue)
        keychain.remove(forKey: fcmTokenKey.rawValue)
    }
}
