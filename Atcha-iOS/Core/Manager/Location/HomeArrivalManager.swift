//
//  HomeArrivalManager.swift
//  Atcha-iOS
//
//  Created by wodnd on 3/11/26.
//

import Foundation
import CoreLocation
import UserNotifications
import UIKit

final class HomeArrivalManager {
    static let shared = HomeArrivalManager()
    private init() {}
    
    private var isArrivalSignalSent = false
    
    func checkHomeArrival(currentCoord: CLLocationCoordinate2D) {
        let wrapper = UserDefaultsWrapper.shared
        
        guard wrapper.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) == true else {
            isArrivalSignalSent = false
            return
        }
        
        guard !isArrivalSignalSent else { return }
        
        let homeLat = wrapper.double(forKey: UserDefaultsWrapper.Key.homeLat.rawValue) ?? 0.0
        let homeLon = wrapper.double(forKey: UserDefaultsWrapper.Key.homeLon.rawValue) ?? 0.0
        
        guard homeLat != 0 && homeLon != 0 else { return }
        
        let homeLoc = CLLocation(latitude: homeLat, longitude: homeLon)
        let currentLoc = CLLocation(latitude: currentCoord.latitude, longitude: currentCoord.longitude)
        
        let distance = currentLoc.distance(from: homeLoc)
        
        if distance <= 50 {
            isArrivalSignalSent = true
            
            AlarmManager.shared.cancelArrivalTimeout()
            
            AlarmManager.shared.sendImmediateLocalPush(
                title: "막차 안내 종료",
                body: "목적지 부근에 도착했어요",
                playSound: true
            )
            
            NotificationCenter.default.post(name: NSNotification.Name("userArrivedHome"), object: nil)
        }
    }
    
    func reset() {
        isArrivalSignalSent = false
        AlarmManager.shared.cancelArrivalTimeout()
    }
}
