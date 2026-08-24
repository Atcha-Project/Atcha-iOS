import Foundation

/// Codable: 세션 스냅샷의 수단 기록용(LA 재시작 아이콘 분기) — 미지 케이스 디코딩 실패는
/// 스냅샷 어댑터가 nil로 무해화한다.
public enum TransportMode: Equatable, Sendable, Codable {
    case walk
    case bus
    case subway
    case unknown
}

public struct RoutePoint: Equatable, Sendable {
    public let name: String
    public let coordinate: Coordinate

    public init(name: String, coordinate: Coordinate) {
        self.name = name
        self.coordinate = coordinate
    }
}

public struct TransportLeg: Equatable, Sendable {
    public let mode: TransportMode
    /// 초 단위
    public let sectionTime: Int
    /// 미터 단위
    public let distance: Int
    public let departureTime: Date?
    /// 버스는 "타입:번호"(예: "간선:472"), 지하철은 노선명
    public let routeName: String?
    /// 노선 타입 코드 — 아이콘·색상 키
    public let lineType: String?
    public let start: RoutePoint?
    public let end: RoutePoint?
    public let subwayFinalStation: String?
    public let subwayDirection: String?
    public let isExpressSubway: Bool
    public let isLastSubway: Bool

    public init(
        mode: TransportMode,
        sectionTime: Int,
        distance: Int,
        departureTime: Date?,
        routeName: String?,
        lineType: String?,
        start: RoutePoint?,
        end: RoutePoint?,
        subwayFinalStation: String?,
        subwayDirection: String?,
        isExpressSubway: Bool,
        isLastSubway: Bool
    ) {
        self.mode = mode
        self.sectionTime = sectionTime
        self.distance = distance
        self.departureTime = departureTime
        self.routeName = routeName
        self.lineType = lineType
        self.start = start
        self.end = end
        self.subwayFinalStation = subwayFinalStation
        self.subwayDirection = subwayDirection
        self.isExpressSubway = isExpressSubway
        self.isLastSubway = isLastSubway
    }
}

// 지도 표시 전용 필드(passShape/passStopList/step)는 2.0 스코프에 없어 이식하지 않았다.
public struct LastRoute: Equatable, Sendable {
    public let id: String
    /// 막차 출발 시각
    public let departureTime: Date
    /// 초 단위
    public let totalTime: Int
    /// 초 단위
    public let totalWalkTime: Int
    public let transferCount: Int
    /// 미터 단위
    public let totalDistance: Int
    /// 미터 단위
    public let totalWalkDistance: Int
    public let legs: [TransportLeg]

    public init(
        id: String,
        departureTime: Date,
        totalTime: Int,
        totalWalkTime: Int,
        transferCount: Int,
        totalDistance: Int,
        totalWalkDistance: Int,
        legs: [TransportLeg]
    ) {
        self.id = id
        self.departureTime = departureTime
        self.totalTime = totalTime
        self.totalWalkTime = totalWalkTime
        self.transferCount = transferCount
        self.totalDistance = totalDistance
        self.totalWalkDistance = totalWalkDistance
        self.legs = legs
    }
}
