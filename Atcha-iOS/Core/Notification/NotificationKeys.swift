//
//  NotificationKeys.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 8/30/25.
//

import Foundation

extension Notification.Name {
    static let fcmDidReceiveRefresh = Notification.Name("fcmDidReceiveRefresh")
    static let refreshDidUpdate = Notification.Name("refreshDidUpdate") 
    static let alarmPushTapped = Notification.Name("alarmPushTapped")
    static let apiErrorOccurred = Notification.Name("apiErrorOccurred")
}
