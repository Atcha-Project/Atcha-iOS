public protocol LastRouteRepository: Sendable {
    func searchLastRoutes(start: Coordinate, end: Coordinate) async throws -> [LastRoute]
    func lastRoute(id: String) async throws -> LastRoute
}
