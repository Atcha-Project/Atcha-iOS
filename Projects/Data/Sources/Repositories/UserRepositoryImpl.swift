import CoreNetwork
import Domain

public struct UserRepositoryImpl: UserRepository {
    private let networkClient: any NetworkClient

    /// 서버 토큰 데코레이터가 적용된 클라이언트를 주입할 것 — `/members/me` 계열은
    /// access 토큰 Bearer + 401 세션 복구의 일반 규약을 따른다.
    public init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    public func fetchMe() async throws -> UserProfile {
        let dto: UserInfoResponseDTO = try await networkClient.requestEnveloped(UserEndpoint.me)
        return dto.toEntity()
    }

    public func updateHomeAddress(address: String?, coordinate: Coordinate?) async throws {
        let _: UserInfoPatchResponseDTO = try await networkClient.requestEnveloped(
            UserEndpoint.updateHomeAddress(
                HomePatchRequestDTO(
                    address: address,
                    lat: coordinate?.latitude,
                    lon: coordinate?.longitude
                )
            )
        )
    }

    public func updateAlertFrequencies(_ frequencies: [Int]) async throws {
        let _: UserInfoPatchResponseDTO = try await networkClient.requestEnveloped(
            UserEndpoint.updateAlertFrequencies(AlertFrequencyPatchRequestDTO(alertFrequencies: frequencies))
        )
    }

    public func withdraw(reason: String?) async throws {
        let _: APIEmptyResult = try await networkClient.requestEnveloped(
            UserEndpoint.withdraw(WithdrawRequestDTO(reason: reason))
        )
    }
}
