//
//  BusRealTimeInfoResponse.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation

struct BusRealTimeInfoResponse: Codable {
    let busRouteId: String?
    let routeName: String?
    let serviceRegion: String?
    let busStationId: String?
    let stationName: String?
    let lastTime: String?
    let term: Int?
    let realTimeBusArrival: [RealTimeBusArrivalResponse]?
}

struct RealTimeBusArrivalResponse: Codable {
    let busStatus: String?
    let remainingTime: Int?
    let busCongestion: String?
    let remainingSeats: Int?
    let expectedArrivalTime: String?
    let vehicleId: String?
    let remainingStations: Int?
}

extension BusRealTimeInfoResponse {
    func toEntity() -> BusRealTimeInfo? {
        guard
            let busRouteId = busRouteId,
            let routeName = routeName,
            let serviceRegion = serviceRegion,
            let busStationId = busStationId,
            let stationName = stationName,
            let lastTime = lastTime,
            let term = term,
            let realTimeBusArrival = realTimeBusArrival
        else {
            return nil
        }
        
        return BusRealTimeInfo(
            busRouteId: busRouteId,
            routeName: routeName,
            serviceRegion: serviceRegion,
            busStationId: busStationId,
            stationName: stationName,
            lastTime: lastTime,
            term: term,
            realTimeBusArrival: realTimeBusArrival.compactMap { $0.toEntity() }
        )
    }
}

extension RealTimeBusArrivalResponse {
    func toEntity() -> RealTimeBusArrival? {
        guard
            let busStatus = busStatus,
            let remainingTime = remainingTime,
            let busCongestion = busCongestion,
            let remainingSeats = remainingSeats,
            let expectedArrivalTime = expectedArrivalTime,
            let vehicleId = vehicleId,
            let remainingStations = remainingStations
        else {
            return nil
        }
        
        return RealTimeBusArrival(
            busStatus: busStatus,
            remainingTime: remainingTime,
            busCongestion: busCongestion,
            remainingSeats: remainingSeats,
            expectedArrivalTime: expectedArrivalTime,
            vehicleId: vehicleId,
            remainingStations: remainingStations
        )
    }
}
