//
//  BusCourse.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation

// 버스 운행 상태
enum BusStatus: String, Codable {
    case waiting = "WAITING"
    case soon = "SOON"
    case operating = "OPERATING"
    case end = "END"
}

// 버스 정보 유형
enum BusInfoType: String, Codable {
    case realTime = "REALTIME"
    case estimated = "ESTIMATED"
}

struct BusRealTimeInfo: Codable {
    let busRouteId: String?
    let routeName: String?
    let serviceRegion: String?
    let busStationId: String?
    let stationName: String?
    let lastTime: String?
    let term: Int?
    let realTimeBusArrival: [RealTimeBusArrival]?
}

struct RealTimeBusArrival: Codable {
    let routeName: String?
    let busStatus: BusStatus?
    var remainingTime: Int?
    let remainingStations: Int?
    let isLast: Bool?
    let busCongestion: BusCongestion?
    let remainingSeats: Int?
    let expectedArrivalTime: String?
    let vehicleId: String?
    let infoType: BusInfoType?
}

extension BusRealTimeInfo {
    func toBusRouteInfo() -> BusRouteInfo {
        return BusRouteInfo(
            busRouteId: busRouteId,
            routeName: routeName,
            serviceRegion: serviceRegion
        )
    }
}
