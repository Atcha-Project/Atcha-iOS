/// 푸시 토큰 포트 — `/auth/login`의 fcmToken 파라미터 소싱용.
/// V2는 FCM 토큰 서버 전달이 미정(미확정 #5)이라 nil이 일반 상태다.
public protocol PushTokenProviding: Sendable {
    func currentPushToken() async -> String?
}
