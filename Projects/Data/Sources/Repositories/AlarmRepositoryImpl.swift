import CoreNetwork
import Domain

public struct AlarmRepositoryImpl: AlarmRepository {
    private let networkClient: any NetworkClient

    public init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    public func register(lastRouteId: String) async throws {
        let _: APIEmptyResult = try await networkClient.requestEnveloped(
            AlarmEndpoint.register(AlarmRegisterRequestDTO(lastRouteId: lastRouteId))
        )
    }

    public func cancel(lastRouteId: String) async throws {
        let _: APIEmptyResult = try await networkClient.requestEnveloped(
            AlarmEndpoint.cancel(lastRouteId: lastRouteId)
        )
    }

    public func refresh() async throws -> AlarmInfo {
        let dto: AlarmRefreshResponseDTO = try await networkClient.requestEnveloped(AlarmEndpoint.refresh)
        guard let info = dto.toEntity() else {
            throw NetworkError.decoding(underlying: MissingResultError())
        }
        return info
    }
}
