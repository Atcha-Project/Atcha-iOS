/// 소셜 SDK 포트 — 어댑터 구현은 App에 둔다(외부 SDK는 앱 타겟에서만 링크).
/// 제공자 UI(카카오톡 전환·Apple 시트)를 띄우므로 메인 액터 격리.
public protocol SocialLoginService: Sendable {
    @MainActor func authorize(provider: SocialLoginProvider) async throws -> SocialCredential
}
