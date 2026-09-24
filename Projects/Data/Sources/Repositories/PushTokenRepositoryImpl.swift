import CoreNetwork
import Domain

public struct PushTokenRepositoryImpl: PushTokenRepository {
    private let networkClient: any NetworkClient

    /// 서버 토큰 데코레이터가 적용된 클라이언트를 주입할 것 — 게스트 JWT가 필요한 API다.
    public init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    // 응답 본문 형태는 미정 — 2xx면 성공으로 본다(APIEmptyResult 규약).
    public func register(token: String) async throws {
        let _: APIEmptyResult = try await networkClient.requestEnveloped(
            UserEndpoint.updateFcmToken(FcmTokenUpdateRequestDTO(fcmToken: token))
        )
    }
}
