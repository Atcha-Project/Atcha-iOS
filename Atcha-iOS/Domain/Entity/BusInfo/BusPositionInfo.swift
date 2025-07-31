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
