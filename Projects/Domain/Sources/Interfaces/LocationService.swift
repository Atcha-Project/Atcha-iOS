/// 디바이스 위치 포트 — 어댑터 구현은 Phase 6에서 App에 둔다.
public protocol LocationService: Sendable {
    func currentLocation() async throws -> Coordinate
}
