//
//  BusCourse.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation

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
    let busStatus: String?
    let remainingTime: Int?
    let busCongestion: String?
    let remainingSeats: Int?
    let expectedArrivalTime: String?
    let vehicleId: String?
    let remainingStations: Int?
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
