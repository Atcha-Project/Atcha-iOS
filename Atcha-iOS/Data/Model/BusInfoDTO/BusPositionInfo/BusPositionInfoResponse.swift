//
//  BusPositionInfoResponse.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation

struct BusPositionInfoResponse: Codable {
    let busRouteStationList: [BusRouteStationListResponse]?
    let turnPoint: Int?
    let busPositions: [BusPositionsResponse]?
}

struct BusRouteStationListResponse: Codable {
    let busRouteId: String?
    let busRouteName: String?
    let busStationId: String?
    let busStationNumber: String?
    let busStationName: String?
    let busStationLat: Double?
    let busStationLon: Double?
    let order: Int?
}

struct BusPositionsResponse: Codable {
    let vehicleId: String?
    let sectionOrder: Int?
    let vehicleNumber: String?
    let sectionProgress: Double?
    let busCongestion: String?
    let remainSeats: Int?
}

extension BusPositionInfoResponse {
    func toEntity() -> BusPositionInfo? {
        return BusPositionInfo(
            busRouteStationList: busRouteStationList?.compactMap { $0.toEntity() },
            turnPoint: turnPoint,
            busPositions: busPositions?.compactMap { $0.toEntity() }
        )
    }
}

extension BusRouteStationListResponse {
    func toEntity() -> BusRouteStationList? {
        guard
            let busRouteId = busRouteId,
            let busRouteName = busRouteName,
            let busStationId = busStationId,
            let busStationNumber = busStationNumber,
            let busStationName = busStationName,
            let busStationLat = busStationLat,
            let busStationLon = busStationLon,
            let order = order
        else {
            return nil
        }
        
        return BusRouteStationList(
            busRouteId: busRouteId,
            busRouteName: busRouteName,
            busStationId: busStationId,
            busStationNumber: busStationNumber,
            busStationName: busStationName,
            busStationLat: busStationLat,
            busStationLon: busStationLon,
            order: order
        )
    }
}

extension BusPositionsResponse {
    func toEntity() -> BusPositions {
        return BusPositions(
            vehicleId: vehicleId,
            sectionOrder: sectionOrder,
            vehicleNumber: vehicleNumber,
            sectionProgress: sectionProgress,
            busCongestion: busCongestion,
            remainSeats: remainSeats
        )
    }
}
