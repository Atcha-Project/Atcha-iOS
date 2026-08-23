import Foundation

// TODO: [미확정] 서버 계산 "알람 시각" 필드는 refresh 응답에 없다(실측: departureTime뿐) —
//       알람 시각 스펙이 확정되면 여기에 추가한다.
/// Codable: 세션 스냅샷(`AlarmSessionSnapshot`) 영속화용 — 재실행 브리지이지 정본이 아니다.
public struct AlarmInfo: Equatable, Sendable, Codable {
    public let lastRouteId: String
    /// 막차 출발 시각 (서버 재계산 값)
    public let departureTime: Date?
    public let updatedAt: Date?
    public let isReal: Bool

    public init(lastRouteId: String, departureTime: Date?, updatedAt: Date?, isReal: Bool) {
        self.lastRouteId = lastRouteId
        self.departureTime = departureTime
        self.updatedAt = updatedAt
        self.isReal = isReal
    }
}
