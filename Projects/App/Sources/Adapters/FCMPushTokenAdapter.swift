import Domain
import FirebaseCore
import FirebaseMessaging

/// `/auth/login`의 fcmToken 소싱 — V2는 GoogleService-Info.plist가 레거시 번들용이라
/// Firebase 미구성이 보통이고, 그때는 nil(→ 엔드포인트가 빈 문자열 전송, 레거시 관용).
/// FCM 토큰 서버 전달 정식화는 기존 미확정 #5 그대로.
struct FCMPushTokenAdapter: PushTokenProviding {
    func currentPushToken() async -> String? {
        // configure() 전에 Messaging.messaging()을 만지면 크래시 — 구성 여부로 가드.
        guard FirebaseApp.app() != nil else { return nil }
        return Messaging.messaging().fcmToken
    }
}
