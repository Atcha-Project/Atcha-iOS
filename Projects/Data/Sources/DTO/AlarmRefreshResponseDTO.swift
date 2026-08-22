import Domain
import Foundation

public struct AlarmRefreshResponseDTO: Decodable, Sendable {
    public let departureTime: String?
    public let updatedAt: String?
    public let lastRouteId: String?
    // 서버가 Bool이 아니라 "true"/"false" 문자열로 준다 (레거시 실측).
    public let isReal: String?

    public func toEntity() -> AlarmInfo? {
        guard let lastRouteId else { return nil }
        return AlarmInfo(
            lastRouteId: lastRouteId,
            departureTime: departureTime.flatMap { ServerDateParser.date(from: $0) },
            updatedAt: updatedAt.flatMap { ServerDateParser.date(from: $0) },
            isReal: isReal == "true"
        )
    }
}
