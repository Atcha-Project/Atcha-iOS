// 조회 전용 GET /routes/user-routes는 서버에 없다(레거시 실측) — refresh가 조회를 겸한다.
// TODO: [미확정] 서버에 조회 API가 생기면 별도 메서드로 분리한다.
public protocol AlarmRepository: Sendable {
    func register(lastRouteId: String) async throws
    func cancel(lastRouteId: String) async throws
    func refresh() async throws -> AlarmInfo
}
