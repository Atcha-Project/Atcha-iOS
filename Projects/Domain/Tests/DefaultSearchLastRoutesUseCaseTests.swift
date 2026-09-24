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

    /// 2026-09-25 실측: 같은 지점으로 조회하면 서버가 `TRS_011`
    /// ("출발지와 도착지 간 거리가 너무 가깝습니다")를 준다. **정상 상태를 에러 코드로**
    /// 알리는 경우라, 매핑이 비어 있던 동안에는 그대로 throw되어 화면에
    /// "검색에 실패했어요"만 떴다 — 사용자는 무엇을 바꿔야 하는지 알 수 없었다.
    @Test
    func execute_tooCloseServerCode_returnsNoRoute() async throws {
        let sut = DefaultSearchLastRoutesUseCase(
            repository: StubLastRouteRepository(routes: [], error: ServerError(code: "TRS_011"))
        )

        #expect(try await sut.execute(start: start, end: end) == .noRoute)
    }

    /// 2026-09-25 실측: 권역 밖(부산) 조회 → `TRS_012` "서비스 지역이 아닙니다".
    /// `noRoute`와 회복 경로가 다르다 — 다른 경로를 찾아 줄 수 없고 목적지를 바꿔야 한다.
    @Test
    func execute_outOfServiceRegionServerCode_returnsOutOfServiceRegion() async throws {
        let sut = DefaultSearchLastRoutesUseCase(
            repository: StubLastRouteRepository(routes: [], error: ServerError(code: "TRS_012"))
        )

        #expect(try await sut.execute(start: start, end: end) == .outOfServiceRegion)
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
