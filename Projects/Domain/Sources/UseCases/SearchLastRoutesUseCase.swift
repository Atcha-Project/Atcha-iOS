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
        // TODO: [미확정 #3] 막차 종료의 전용 responseCode는 아직 관측되지 않았다
        //       (2026-09-25 실측 시각이 막차 전이라 재현 못 함). 그때까지 빈 목록을 종료로 간주한다.
        guard !routes.isEmpty else { return .serviceEnded }
        return .available(routes)
    }

    /// 서버가 **정상 상태를 에러 코드로 알리는** 경우를 결과로 되돌린다. 매핑이 비어 있던
    /// 동안 이 둘은 그대로 throw되어 화면에 "검색에 실패했어요"만 떴다 — 사용자는 무엇을
    /// 바꿔야 하는지 알 수 없었다.
    ///
    /// 2026-09-25 실측:
    /// - `TRS_011` "출발지와 도착지 간 거리가 너무 가깝습니다." (같은 지점으로 조회)
    /// - `TRS_012` "서비스 지역이 아닙니다: (129.0415, 35.1151)" (부산으로 조회)
    private static func normalizedResult(code: String) -> LastRouteSearchResult? {
        switch code {
        case "TRS_011": .noRoute
        case "TRS_012": .outOfServiceRegion
        default: nil
        }
    }
}
