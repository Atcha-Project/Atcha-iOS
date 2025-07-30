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
