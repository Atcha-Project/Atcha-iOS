import FirebaseCore
import FirebaseMessaging
import UIKit
import os

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    // 조합 루트는 AppDelegate가 소유한다 — 사일런트 푸시가 scene 없이 백그라운드로
    // 앱을 깨워도 AlarmSyncService에 닿을 수 있어야 한다.
    let container = AppDIContainer()

    /// plist 부재 = FCM 경로 완전 비활성 (등록·델리게이트·수신 전부 dead-path).
    /// 갱신은 폴링(앱 시작·포그라운드 복귀)만으로 성립한다.
    private var isFirebaseEnabled = false

    private static let fcmLogger = Logger(subsystem: "com.atcha.iOS.v2", category: "FCM")

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 고아 LA 재부착/정리 (Phase 14) — 인증 부트스트랩과 무관한 로컬 리컨실이라
        // 앱 시작 최전선에서 1회. 첫 sync보다 먼저 끝나는 것이 보통이지만, 늦어도
        // 어댑터(actor)가 직렬화하므로 안전하다.
        let container = container
        Task { await container.reattachOrphanLiveActivities() }
        configureFirebaseIfAvailable()
        if isFirebaseEnabled {
            Messaging.messaging().delegate = self
            // 사일런트 푸시는 사용자 알림 권한이 필요 없다 —
            // UNUserNotificationCenter.requestAuthorization을 호출하지 않는다.
            application.registerForRemoteNotifications()
        }
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    }

    private func configureFirebaseIfAvailable() {
        // A GoogleService-Info.plist for com.atcha.iOS.v2 is not provisioned
        // yet; configure() without it crashes, so guard on the resource.
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return
        }
        FirebaseApp.configure()
        isFirebaseEnabled = true
    }

    // MARK: - 원격 알림 (사일런트 푸시)

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        guard isFirebaseEnabled else { return }
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
        Self.fcmLogger.error("APNs 등록 실패: \(error.localizedDescription, privacy: .public)")
    }

    /// content-available=1 수신 → 갱신 일원화 지점(AlarmSyncService)으로 위임.
    /// 서버는 레거시와 같은 payload(`type: REFRESH`)를 보낸다 — 그 외 타입은 무시.
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        guard isFirebaseEnabled else { return .noData }
        guard userInfo["type"] as? String == "REFRESH" else { return .noData }
        Self.fcmLogger.info("사일런트 푸시 수신(REFRESH) → 알람 동기화 시작")
        return await container.alarmSyncService.syncFromPush()
    }
}

extension AppDelegate: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // TODO: [미확정 #5] 익명 체계에서의 FCM 토큰 서버 전달 방식 확정 전까지 로깅만 한다.
        Self.fcmLogger.info("FCM 토큰 수신(서버 전달 보류): \(fcmToken ?? "nil", privacy: .private)")
    }
}
