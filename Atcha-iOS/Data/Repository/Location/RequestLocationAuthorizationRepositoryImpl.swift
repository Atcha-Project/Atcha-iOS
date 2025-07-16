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

final class PermissionRepositoryImpl: PermissionRepository {
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
        let manager = CLLocationManager()
        return await withCheckedContinuation { continuation in
            manager.requestWhenInUseAuthorization()
            continuation.resume(returning: manager.authorizationStatus)
        }
    }
}
