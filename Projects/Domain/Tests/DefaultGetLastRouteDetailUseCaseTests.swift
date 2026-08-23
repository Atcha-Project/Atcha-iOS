@testable import Domain
import Foundation
import Testing

private struct StubError: Error {}

private struct StubLastRouteRepository: LastRouteRepository {
    var result: Result<LastRoute, any Error>

    func searchLastRoutes(start: Coordinate, end: Coordinate) async throws -> [LastRoute] { [] }

    func lastRoute(id: String) async throws -> LastRoute {
        try result.get()
    }
}

private let fixture = LastRoute(
    id: "route-1", departureTime: Date(timeIntervalSince1970: 1_000), totalTime: 0,
    totalWalkTime: 0, transferCount: 0, totalDistance: 0, totalWalkDistance: 0, legs: []
)

struct DefaultGetLastRouteDetailUseCaseTests {
    @Test
    func execute_returnsRepositoryDetail() async throws {
        let sut = DefaultGetLastRouteDetailUseCase(
            repository: StubLastRouteRepository(result: .success(fixture))
        )
        #expect(try await sut.execute(routeId: "route-1") == fixture)
    }

    @Test
    func execute_repositoryFails_rethrows() async {
        let sut = DefaultGetLastRouteDetailUseCase(
            repository: StubLastRouteRepository(result: .failure(StubError()))
        )
        await #expect(throws: StubError.self) {
            _ = try await sut.execute(routeId: "route-1")
        }
    }
}
