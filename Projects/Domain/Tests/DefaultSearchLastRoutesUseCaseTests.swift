@testable import Domain
import Foundation
import Testing

private struct StubError: Error {}

private struct StubLastRouteRepository: LastRouteRepository {
    let routes: [LastRoute]
    var error: Error? = nil

    func searchLastRoutes(start: Coordinate, end: Coordinate) async throws -> [LastRoute] {
        if let error { throw error }
        return routes
    }

    func lastRoute(id: String) async throws -> LastRoute {
        if let error { throw error }
        guard let route = routes.first else { throw StubError() }
        return route
    }
}

private extension LastRoute {
    static func fixture(id: String) -> LastRoute {
        LastRoute(
            id: id,
            departureTime: Date(timeIntervalSince1970: 1_000),
            totalTime: 0,
            totalWalkTime: 0,
            transferCount: 0,
            totalDistance: 0,
            totalWalkDistance: 0,
            legs: []
        )
    }
}

struct DefaultSearchLastRoutesUseCaseTests {
    private let start = Coordinate(latitude: 37.49794, longitude: 127.02761)
    private let end = Coordinate(latitude: 37.554722, longitude: 126.970833)

    @Test
    func execute_nonEmptyRoutes_returnsAvailablePreservingOrder() async throws {
        let routes = [LastRoute.fixture(id: "latest"), LastRoute.fixture(id: "alternative")]
        let sut = DefaultSearchLastRoutesUseCase(repository: StubLastRouteRepository(routes: routes))
        let result = try await sut.execute(start: start, end: end)
        #expect(result == .available(routes))
    }

    @Test
    func execute_emptyRoutes_returnsServiceEnded() async throws {
        let sut = DefaultSearchLastRoutesUseCase(repository: StubLastRouteRepository(routes: []))
        let result = try await sut.execute(start: start, end: end)
        #expect(result == .serviceEnded)
    }

    @Test
    func execute_unknownServerError_rethrows() async {
        let sut = DefaultSearchLastRoutesUseCase(
            repository: StubLastRouteRepository(routes: [], error: ServerError(code: "LRT_999"))
        )
        await #expect(throws: ServerError(code: "LRT_999")) {
            try await sut.execute(start: start, end: end)
        }
    }
}
