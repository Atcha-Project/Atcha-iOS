/// 소셜 로그인 전 과정: 소셜 인가 → 가입 여부 확인 → 토큰 교환(기존 회원) 또는
/// 최소 가입(신규 — 온보딩 화면 없이 현재 위치 기반 폼) → 세션 채택.
/// 소셜 UI를 띄우는 authorize가 메인 액터 격리라 execute도 @MainActor.
public protocol SignInUseCase: Sendable {
    @MainActor func execute(provider: SocialLoginProvider) async throws
}

public final class DefaultSignInUseCase: SignInUseCase {
    private let socialLoginService: any SocialLoginService
    private let authRepository: any AuthRepository
    private let sessionStore: any SessionStoring
    private let pushTokenProvider: any PushTokenProviding
    private let getCurrentLocationUseCase: any GetCurrentLocationUseCase
    private let reverseGeocodeUseCase: any ReverseGeocodeUseCase
    private let locationTimeout: Duration

    public init(
        socialLoginService: any SocialLoginService,
        authRepository: any AuthRepository,
        sessionStore: any SessionStoring,
        pushTokenProvider: any PushTokenProviding,
        getCurrentLocationUseCase: any GetCurrentLocationUseCase,
        reverseGeocodeUseCase: any ReverseGeocodeUseCase,
        locationTimeout: Duration = .seconds(8)
    ) {
        self.socialLoginService = socialLoginService
        self.authRepository = authRepository
        self.sessionStore = sessionStore
        self.pushTokenProvider = pushTokenProvider
        self.getCurrentLocationUseCase = getCurrentLocationUseCase
        self.reverseGeocodeUseCase = reverseGeocodeUseCase
        self.locationTimeout = locationTimeout
    }

    @MainActor
    public func execute(provider: SocialLoginProvider) async throws {
        let credential = try await socialLoginService.authorize(provider: provider)
        let fcmToken = await pushTokenProvider.currentPushToken()
        let session: LoginSession
        if try await authRepository.checkRegistration(credential: credential) {
            session = try await authRepository.login(credential: credential, fcmToken: fcmToken)
        } else {
            session = try await authRepository.signUp(
                credential: credential,
                form: await makeMinimalForm(),
                fcmToken: fcmToken
            )
        }
        try await sessionStore.store(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken
        )
    }

    /// 최소 가입 폼 — 위치 실패(권한 거부·타임아웃)면 레거시 실측 폴백,
    /// 역지오코딩만 실패하면 주소만 빈 문자열로 강등한다.
    private func makeMinimalForm() async -> SignUpForm {
        guard let coordinate = await currentCoordinate() else {
            return .minimalFallback
        }
        let address = (try? await reverseGeocodeUseCase.execute(coordinate: coordinate))?.address ?? ""
        return SignUpForm(
            userName: "",
            address: address,
            coordinate: coordinate,
            alertFrequencies: SignUpForm.defaultAlertFrequencies
        )
    }

    /// 위치 조회는 권한 프롬프트 대기 등으로 길어질 수 있어 타임아웃과 레이스한다 —
    /// 가입이 위치 때문에 무한정 막히면 안 된다.
    private func currentCoordinate() async -> Coordinate? {
        let locationUseCase = getCurrentLocationUseCase
        let timeout = locationTimeout
        return await withTaskGroup(of: Coordinate?.self) { group in
            group.addTask { try? await locationUseCase.execute() }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
