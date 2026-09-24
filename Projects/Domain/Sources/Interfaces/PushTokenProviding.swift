/// 푸시 토큰 포트 — 게스트 발급 요청의 fcmToken 소싱용.
/// V2용 GoogleService-Info.plist가 없으면 nil이 일반 상태다.
public protocol PushTokenProviding: Sendable {
    func currentPushToken() async -> String?
}
