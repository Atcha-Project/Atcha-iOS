//
//  RequestLocationAuthorizationRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation
import UserNotifications
import UIKit

final class PermissionRepositoryImpl: NSObject, PermissionRepository {
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func askPushPermission() async -> Bool {
        let granted = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
        
        if granted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        
        return granted
    }
    
    func askLocationPermission() async -> CLAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            guard locationContinuation == nil else {
                continuation.resume(returning: manager.authorizationStatus)
                return
            }
            
            locationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }
}

extension PermissionRepositoryImpl: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let continuation = locationContinuation else { return }
        
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }
        
        continuation.resume(returning: status)
        locationContinuation = nil
    }
}
