import CoreNetwork
import Domain

public struct AuthRepositoryImpl: AuthRepository {
    private let networkClient: any NetworkClient

    /// plain client(AuthenticatedNetworkClient 미적용)를 주입할 것 — 발급 요청은 토큰이 없고,
    /// 401이 세션 복구를 촉발해서도 안 된다.
    public init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    public func issueGuestSession(deviceID: String, fcmToken: String?) async throws -> LoginSession {
        let dto: LoginResponseDTO = try await networkClient.requestEnveloped(
            AuthEndpoint.guest(GuestSessionRequestDTO(deviceId: deviceID, fcmToken: fcmToken))
        )
        return try dto.toEntity()
    }
}
