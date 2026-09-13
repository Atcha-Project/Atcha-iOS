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
}
