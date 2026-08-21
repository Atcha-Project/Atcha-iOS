import CoreNetwork
import Domain

public struct HomeRepositoryImpl: HomeRepository {
    private let networkClient: any NetworkClient

    public init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    public func fetchHomeSummary() async throws -> HomeSummary {
        let dto: HomeSummaryResponseDTO = try await networkClient.request(
            HomeEndpoint.summary(HomeSummaryRequestDTO(userID: "me"))
        )
        return dto.toEntity()
    }
}
