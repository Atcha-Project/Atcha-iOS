//
//  BusPositionInfo.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation

struct BusPositionInfo: Codable {
    let busRouteStationList: [BusRouteStationList]?
    let turnPoint: Int?
    let busPositions: [BusPositions]?
}

struct BusRouteStationList: Codable {
    let busRouteId: String?
    let busRouteName: String?
    let busStationId: String?
    let busStationNumber: String?
    let busStationName: String?
    let busStationLat: Double?
    let busStationLon: Double?
    let order: Int?
}

struct BusPositions: Codable {
    let vehicleId: String?
    let sectionOrder: Int?
    let vehicleNumber: String?
    let sectionProgress: Double?
    let busCongestion: String?
    let remainSeats: Int?
}


extension BusPositionInfoResponse {
    func toEntity() -> BusPositionInfo? {
        guard
            let busRouteStationList = busRouteStationList,
            let turnPoint = turnPoint,
            let busPositions = busPositions
        else {
            return nil
        }
        
        return BusPositionInfo(
            busRouteStationList: busRouteStationList.compactMap { $0.toEntity() },
            turnPoint: turnPoint,
            busPositions: busPositions.compactMap { $0.toEntity() }
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
    func toEntity() -> BusPositions? {
        guard
            let vehicleId = vehicleId,
            let sectionOrder = sectionOrder,
            let vehicleNumber = vehicleNumber,
            let sectionProgress = sectionProgress,
            let busCongestion = busCongestion,
            let remainSeats = remainSeats
        else {
            return nil
        }
        
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
