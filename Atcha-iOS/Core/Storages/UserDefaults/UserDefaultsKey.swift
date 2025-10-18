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
    
    static let homeLat: UserDefaultsWrapper.Key = "homeLat"
    static let homeLon: UserDefaultsWrapper.Key = "homeLon"
    static let homeAddress: UserDefaultsWrapper.Key = "homeAddress"
    static let buildingName: UserDefaultsWrapper.Key = "buildingName"
    
    static let soundType: UserDefaultsWrapper.Key = "soundType"
    
    static let legInfo: UserDefaultsWrapper.Key = "legInfo"
    static let addressDesc: UserDefaultsWrapper.Key = "addressDesc"
    
    static let startLat: UserDefaultsWrapper.Key = "startLat"
    static let startLon: UserDefaultsWrapper.Key = "startLon"
    static let startAddress: UserDefaultsWrapper.Key = "startAdress"
    
    static let lastRouteId: UserDefaultsWrapper.Key = "lastRouteId"
    static let departureTime: UserDefaultsWrapper.Key = "departureTime" // 막차 출발 시간
    static let arrivalTime: UserDefaultsWrapper.Key = "arrivalTime" // 막차 집 도착 시간 
//    static let trainRealTime: UserDefaultsWrapper.Key = "trainRealTime"
    
    static let alarmVolume: UserDefaultsWrapper.Key = "alarmVolume"
    static let alarmOption: UserDefaultsWrapper.Key = "alarmOption"
    
    static let alarmRegister: UserDefaultsWrapper.Key = "alarmRegister"
}
