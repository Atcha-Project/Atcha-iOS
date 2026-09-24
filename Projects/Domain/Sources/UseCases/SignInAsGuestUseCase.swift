/// 게스트 부트스트랩: deviceId(+있으면 FCM 토큰)로 서버 토큰 쌍을 받아 세션에 채택한다.
/// 소셜 로그인과 달리 UI·위치·역지오코딩이 개입하지 않으므로 메인 액터 격리가 필요 없다.
public protocol SignInAsGuestUseCase: Sendable {
    func execute() async throws
}

public final class DefaultSignInAsGuestUseCase: SignInAsGuestUseCase {
    private let authRepository: any AuthRepository
    private let sessionStore: any SessionStoring
    private let deviceIdentifierProvider: any DeviceIdentifierProviding
    private let pushTokenProvider: any PushTokenProviding

    public init(
        authRepository: any AuthRepository,
        sessionStore: any SessionStoring,
        deviceIdentifierProvider: any DeviceIdentifierProviding,
        pushTokenProvider: any PushTokenProviding
    ) {
        self.authRepository = authRepository
        self.sessionStore = sessionStore
        self.deviceIdentifierProvider = deviceIdentifierProvider
        self.pushTokenProvider = pushTokenProvider
    }

    public func execute() async throws {
        let deviceID = await deviceIdentifierProvider.currentDeviceID()
        // 알림 권한 전이면 nil이 정상 — 이후 PUT /members/me로 갱신한다(SyncPushTokenUseCase).
        let fcmToken = await pushTokenProvider.currentPushToken()
        let session = try await authRepository.signInAsGuest(
            deviceID: deviceID,
            fcmToken: fcmToken
        )
        try await sessionStore.store(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken
        )
    }
}
