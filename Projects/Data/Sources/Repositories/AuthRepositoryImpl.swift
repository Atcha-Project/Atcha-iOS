import CoreNetwork
import Domain

public struct AuthRepositoryImpl: AuthRepository {
    private let networkClient: any NetworkClient

    /// plain client(AuthenticatedNetworkClient 미적용)를 주입할 것 — Authorization에
    /// 소셜 자격 증명을 실어야 하고, 401이 세션 복구를 촉발해서도 안 된다.
    public init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    public func checkRegistration(credential: SocialCredential) async throws -> Bool {
        let dto: AuthCheckResponseDTO = try await networkClient.requestEnveloped(
            AuthEndpoint.check(credential)
        )
        return dto.exists
    }

    public func login(credential: SocialCredential, fcmToken: String?) async throws -> LoginSession {
        let dto: LoginResponseDTO = try await networkClient.requestEnveloped(
            AuthEndpoint.login(credential, fcmToken: fcmToken)
        )
        return try dto.toEntity()
    }

    public func signUp(
        credential: SocialCredential,
        form: SignUpForm,
        fcmToken: String?
    ) async throws -> LoginSession {
        let request = SignUpRequestDTO(
            provider: credential.provider.serverCode,
            userName: form.userName,
            address: form.address,
            lat: form.coordinate.latitude,
            lon: form.coordinate.longitude,
            alertFrequencies: form.alertFrequencies,
            // 레거시 실측: FCM 토큰 부재 시 빈 문자열 전송.
            fcmToken: fcmToken ?? ""
        )
        // 응답 계약은 /auth/login과 동일 — LoginResponseDTO 재사용.
        let dto: LoginResponseDTO = try await networkClient.requestEnveloped(
            AuthEndpoint.signUp(credential, request)
        )
        return try dto.toEntity()
    }
}
