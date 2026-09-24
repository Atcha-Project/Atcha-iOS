/// 게스트 세션 발급 → 세션 채택. 앱 시작(토큰 없음)과 refresh 확정 만료 두 경로가 호출한다.
public protocol IssueGuestSessionUseCase: Sendable {
    func execute() async throws
}

public struct DefaultIssueGuestSessionUseCase: IssueGuestSessionUseCase {
    private let authRepository: any AuthRepository
    private let sessionStore: any SessionStoring
    private let deviceIdentifier: any DeviceIdentifierProviding
    private let pushTokenProvider: any PushTokenProviding

    public init(
        authRepository: any AuthRepository,
        sessionStore: any SessionStoring,
        deviceIdentifier: any DeviceIdentifierProviding,
        pushTokenProvider: any PushTokenProviding
    ) {
        self.authRepository = authRepository
        self.sessionStore = sessionStore
        self.deviceIdentifier = deviceIdentifier
        self.pushTokenProvider = pushTokenProvider
    }

    public func execute() async throws {
        let session = try await authRepository.issueGuestSession(
            deviceID: try deviceIdentifier.deviceID(),
            // 발급 시점에 FCM 토큰을 함께 실어 두면 갱신 API가 없어도 첫 푸시가 성립한다.
            fcmToken: await pushTokenProvider.currentPushToken()
        )
        try await sessionStore.store(accessToken: session.accessToken, refreshToken: session.refreshToken)
    }
}
