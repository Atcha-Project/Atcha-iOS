import Domain
import Foundation

public struct LastRouteResponseDTO: Decodable, Sendable {
    public let routeId: String?
    public let departureDateTime: String?
    public let totalTime: Int?
    public let totalWalkTime: Int?
    public let transferCount: Int?
    public let totalDistance: Int?
    public let totalWalkDistance: Int?
    public let legs: [LegResponseDTO]?

    /// routeId·막차 출발 시각이 없는 항목은 세울 수 없어 nil을 돌려준다 (호출부 compactMap).
    public func toEntity() -> LastRoute? {
        guard let routeId,
              let departureDateTime,
              let departureTime = ServerDateParser.date(from: departureDateTime)
        else { return nil }
        return LastRoute(
            id: routeId,
            departureTime: departureTime,
            totalTime: totalTime ?? 0,
            totalWalkTime: totalWalkTime ?? 0,
            transferCount: transferCount ?? 0,
            totalDistance: totalDistance ?? 0,
            totalWalkDistance: totalWalkDistance ?? 0,
            legs: legs?.map { $0.toEntity() } ?? []
        )
    }
}

// 지도 표시 전용 필드(passStopList/step/passShape 등)는 2.0 스코프에 없어 디코딩하지 않는다.
public struct LegResponseDTO: Decodable, Sendable {
    public let distance: Int?
    public let sectionTime: Int?
    // 레거시는 enum으로 받아 미지의 mode 문자열에서 디코딩이 통째로 실패했다 — String으로 받고 매핑한다.
    public let mode: String?
    public let departureDateTime: String?
    public let route: String?
    public let type: String?
    public let start: RoutePointResponseDTO?
    public let end: RoutePointResponseDTO?
    public let subwayFinalStation: String?
    public let subwayDirection: String?
    public let isExpressSubway: Bool?
    public let isLastSubway: Bool?

    public func toEntity() -> TransportLeg {
        TransportLeg(
            mode: TransportMode(serverValue: mode),
            sectionTime: sectionTime ?? 0,
            distance: distance ?? 0,
            departureTime: departureDateTime.flatMap { ServerDateParser.date(from: $0) },
            routeName: route,
            lineType: type,
            start: start?.toEntity(),
            end: end?.toEntity(),
            subwayFinalStation: subwayFinalStation,
            subwayDirection: subwayDirection,
            isExpressSubway: isExpressSubway ?? false,
            isLastSubway: isLastSubway ?? false
        )
    }
}

public struct RoutePointResponseDTO: Decodable, Sendable {
    public let name: String?
    public let lon: Double?
    public let lat: Double?

    public func toEntity() -> RoutePoint? {
        guard let name, let lat, let lon else { return nil }
        return RoutePoint(name: name, coordinate: Coordinate(latitude: lat, longitude: lon))
    }
}

private extension TransportMode {
    init(serverValue: String?) {
        switch serverValue {
        case "WALK": self = .walk
        case "BUS": self = .bus
        case "SUBWAY": self = .subway
        default: self = .unknown
        }
    }
}
