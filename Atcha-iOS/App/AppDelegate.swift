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
        
        print("📩 Silent Push 수신: \(userInfo)")
        
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

extension AppDelegate {
    /// 앱 실행 후 1분 뒤:
    /// 1) 로컬 푸시(사운드 포함) 울리고
    /// 2) 앱이 포그라운드라면 AlarmManager로 사이렌 재생
    func scheduleTestAlarmUsingStartAlarm() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = .current
        
        let now = Date()
        let departureDate = now.addingTimeInterval(60) // 지금 + 2분
        let departureStr = formatter.string(from: departureDate)
        
        print("테스트 departureTime:", departureStr)
        
        AlarmManager.shared.startAlarm(
            after: departureStr,
            title: "테스트 출발 알람",
            body: "앱 실행 후 1분이 지나서 시작된 테스트 알람이에요."
        )
    }
    
    // AppDelegate.swift 맨 아래쪽에 이미 UNUserNotificationCenterDelegate 채택하고 있으니까 여기에 추가
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        if let alarmType = userInfo["alarmType"] as? String,
           alarmType == "DEPARTURE_ALARM" {
            
            print("🔔 포그라운드에서 출발 알람 수신")
            
            // 앱 안에서 무한 사이렌/진동 시작
            AlarmManager.shared.startImmediateAlarm()
            
            NotificationCenter.default.post(
                name: .alarmPushTapped,
                object: nil,
                userInfo: nil
            )
            
            completionHandler([])
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        if let alarmType = userInfo["alarmType"] as? String,
           alarmType == "DEPARTURE_ALARM" {
            
            print("🔔 알림 탭으로 앱 진입 - 출발 알람 시작")
            
            // 앱 안 무한 알람 시작
            AlarmManager.shared.startImmediateAlarm()
            
            NotificationCenter.default.post(
                name: .alarmPushTapped,
                object: nil,
                userInfo: nil
            )
        }
        
        completionHandler()
    }
}

