//
//  AppDelegate.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/15/25.
//

import UIKit
import KakaoSDKCommon
import FirebaseCore
import FirebaseMessaging
import Firebase
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        
        // MARK: - Kakao
        print("Bundle.main.kakaoInitKey : \(Bundle.main.kakaoApiKey)")
        KakaoSDK.initSDK(appKey: Bundle.main.kakaoApiKey)
        
        // MARK: - Firebase
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        application.registerForRemoteNotifications()
        
        AmplitudeManager.shared.reset()
        
        let savedId = UserDefaultsWrapper.shared.integer(forKey: UserDefaultsWrapper.Key.userId.rawValue)
        AmplitudeManager.shared.start(
            environment: .auto,
            userId: savedId,
            autocapture: [],
            logLevel: .WARN
        )
        AmplitudeManager.shared.flush()
        
        if let registered = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue),registered {
            AlarmManager.shared.setupAudioSession()
            AlarmManager.shared.playLocalMusic(named: "silent", withExtension: "mp3")
        }
        
        if let savedId = UserDefaultsWrapper.shared.integer(forKey: UserDefaultsWrapper.Key.userId.rawValue) {
            AmplitudeManager.shared.bindUser(id: String(savedId))
        }
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging,
                   didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken ?? "")")
        AppDIContainer.shared.tokenStorage.fcmToken = fcmToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("erorr : \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("Silent Push 수신: \(userInfo)")
        
        guard let type = userInfo["type"] as? String else {
            completionHandler(.noData)
            return
        }
        
        if type == "REFRESH" {
            NotificationCenter.default.post(
                name: .fcmDidReceiveRefresh,
                object: nil,
                userInfo: [
                    "updatedAt": userInfo["updatedAt"] as? String ?? "",
                    "body": userInfo["body"] as? String ?? ""
                ]
            )
            
            // 데이터 리프레시 처리 가능
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }
}
