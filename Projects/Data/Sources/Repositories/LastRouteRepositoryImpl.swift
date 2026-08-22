import CoreNetwork
import Domain

public struct LastRouteRepositoryImpl: LastRouteRepository {
    private let networkClient: any NetworkClient

    public init(networkClient: any NetworkClient) {
        self.networkClient = networkClient
    }

    public func searchLastRoutes(start: Coordinate, end: Coordinate) async throws -> [LastRoute] {
        let dtos: [LastRouteResponseDTO] = try await networkClient.requestEnveloped(
            RouteEndpoint.search(start: start, end: end)
        )
        return dtos.compactMap { $0.toEntity() }
    }

    public func lastRoute(id: String) async throws -> LastRoute {
        let dto: LastRouteResponseDTO = try await networkClient.requestEnveloped(
            RouteEndpoint.detail(routeId: id)
        )
        guard let route = dto.toEntity() else {
            throw NetworkError.decoding(underlying: MissingResultError())
        }
        return route
    }
}
