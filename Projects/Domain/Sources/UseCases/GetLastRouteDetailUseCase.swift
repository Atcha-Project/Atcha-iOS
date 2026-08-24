/// 경로 상세 재조회 (Phase 14 카드 복원) — 재실행 후 "알람은 있는데 무슨 경로인지
/// 모르는" 상태를 해소한다. 홈은 alarmSynced 수신 시 카드가 없으면 이걸로 복원한다.
public protocol GetLastRouteDetailUseCase: Sendable {
    func execute(routeId: String) async throws -> LastRoute
}

public struct DefaultGetLastRouteDetailUseCase: GetLastRouteDetailUseCase {
    private let repository: any LastRouteRepository

    public init(repository: any LastRouteRepository) {
        self.repository = repository
    }

    public func execute(routeId: String) async throws -> LastRoute {
        try await repository.lastRoute(id: routeId)
    }
}
