/// 소셜 로그인 제공자 — 서버 provider 파라미터 값(kakao=0, apple=1)은 Data 레이어가 매핑한다.
public enum SocialLoginProvider: Sendable, Equatable, CaseIterable {
    case kakao
    case apple
}

/// 소셜 SDK가 발급한 자격 증명 — 카카오는 OAuth access token, 애플은 identityToken.
/// 서버 `/auth/*` 호출에서 Bearer로 실려 서버 토큰과 교환된다.
public struct SocialCredential: Sendable, Equatable {
    public let provider: SocialLoginProvider
    public let accessToken: String

    public init(provider: SocialLoginProvider, accessToken: String) {
        self.provider = provider
        self.accessToken = accessToken
    }
}

public enum SocialLoginError: Error, Equatable, Sendable {
    /// 사용자가 소셜 로그인 UI를 스스로 닫음 — 에러 표출 없이 idle 복귀.
    case cancelled
    /// 제공자를 쓸 수 없는 상태(카카오 SDK 미초기화 등).
    case providerUnavailable
    /// 그 외 제공자 실패.
    case failed
}
