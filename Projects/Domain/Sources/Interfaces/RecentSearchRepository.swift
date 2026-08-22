/// 로컬 저장 전용 — 구현은 Phase 2(CoreStorage)에서.
public protocol RecentSearchRepository: Sendable {
    func recentSearches() async throws -> [Place]
    func save(_ place: Place) async throws
    func remove(_ place: Place) async throws
}
