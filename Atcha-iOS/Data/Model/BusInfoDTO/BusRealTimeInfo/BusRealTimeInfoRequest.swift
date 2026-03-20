//
//  BusRealTimeInfoRequest.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation

struct BusRealTimeInfoRequest: Codable {
    let routeName: String?
    let stationName: String?
    let lat: Double?
    let lon: Double?
    let passStations: [PassStations]?
}

struct PassStations: Codable, Equatable {
    let index: Int?
    let stationName: String?
    let lat: String?
    let lon: String?
}
