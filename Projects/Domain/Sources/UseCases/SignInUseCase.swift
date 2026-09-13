public enum SignInOutcome: Sendable, Equatable {
    /// 서버 토큰 채택까지 완료 — 홈 진입 가능.
    case success
    /// 미가입 소셜 계정 — 가입 플로우는 후속 Phase, 화면은 안내만 띄운다.
    case needsSignUp
}

/// 소셜 로그인 전 과정: 소셜 인가 → 가입 여부 확인 → (기존 회원이면) 토큰 교환·세션 채택.
/// 소셜 UI를 띄우는 authorize가 메인 액터 격리라 execute도 @MainActor.
public protocol SignInUseCase: Sendable {
    @MainActor func execute(provider: SocialLoginProvider) async throws -> SignInOutcome
}

public final class DefaultSignInUseCase: SignInUseCase {
    private let socialLoginService: any SocialLoginService
    private let authRepository: any AuthRepository
    private let sessionStore: any SessionStoring
    private let pushTokenProvider: any PushTokenProviding

    public init(
        socialLoginService: any SocialLoginService,
        authRepository: any AuthRepository,
        sessionStore: any SessionStoring,
        pushTokenProvider: any PushTokenProviding
    ) {
        self.socialLoginService = socialLoginService
        self.authRepository = authRepository
        self.sessionStore = sessionStore
        self.pushTokenProvider = pushTokenProvider
    }

    @MainActor
    public func execute(provider: SocialLoginProvider) async throws -> SignInOutcome {
        let credential = try await socialLoginService.authorize(provider: provider)
        guard try await authRepository.checkRegistration(credential: credential) else {
            // 미가입 시 소셜 자격 증명을 보관하지 않는다 — 가입 플로우가 없는 현
            // 스코프에서 평문 보관은 위험만 남긴다(레거시의 UserDefaults 보관 미계승).
            return .needsSignUp
        }
        let session = try await authRepository.login(
            credential: credential,
            fcmToken: await pushTokenProvider.currentPushToken()
        )
        try await sessionStore.store(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken
        )
        return .success
    }
}
