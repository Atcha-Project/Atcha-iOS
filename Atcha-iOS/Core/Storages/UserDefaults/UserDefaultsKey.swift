//
//  UserDefaultsKey.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/20/25.
//

import Foundation

public extension UserDefaultsWrapper.Key {
    static let provider: UserDefaultsWrapper.Key = "provider"
    static let providerToken: UserDefaultsWrapper.Key = "providerToken"
    static let userId: UserDefaultsWrapper.Key = "userId"
    
    static let lat: UserDefaultsWrapper.Key = "lat"
    static let lon: UserDefaultsWrapper.Key = "lon"
    static let address: UserDefaultsWrapper.Key = "address"
    static let buildingName: UserDefaultsWrapper.Key = "buildingName"
    
    static let soundType: UserDefaultsWrapper.Key = "soundType"
}
