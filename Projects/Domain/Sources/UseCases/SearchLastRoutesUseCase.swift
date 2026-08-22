public protocol SearchLastRoutesUseCase: Sendable {
    func execute(start: Coordinate, end: Coordinate) async throws -> LastRouteSearchResult
}

public struct DefaultSearchLastRoutesUseCase: SearchLastRoutesUseCase {
    private let repository: any LastRouteRepository

    public init(repository: any LastRouteRepository) {
        self.repository = repository
    }

    public func execute(start: Coordinate, end: Coordinate) async throws -> LastRouteSearchResult {
        let routes: [LastRoute]
        do {
            routes = try await repository.searchLastRoutes(start: start, end: end)
        } catch let error as ServerError {
            if let normalized = Self.normalizedResult(code: error.code) {
                return normalized
            }
            throw error
        }
        // TODO: [미확정 #3] 서버의 "막차 종료" 표현 실측 전까지 빈 목록을 종료로 간주한다.
        guard !routes.isEmpty else { return .serviceEnded }
        return .available(routes)
    }

    // TODO: [미확정 #3] "막차 종료"/"경로 없음"의 responseCode 실측값이 확정되면 이 매핑에만 추가한다.
    //       레거시 단서(의미 미확인): URT_001, LRT_001, LRT_003, REQ_004
    private static func normalizedResult(code: String) -> LastRouteSearchResult? {
        switch code {
        default: nil
        }
    }
}
