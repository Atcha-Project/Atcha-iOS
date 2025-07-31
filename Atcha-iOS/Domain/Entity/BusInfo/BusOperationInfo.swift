//
//  BusInfo.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation

struct BusOperationInfo: Codable {
    let startStationName: String?
    let endStationName: String?
    let serviceHours: [ServiceHours]?
}

struct ServiceHours: Codable {
    let dailyType: String?
    let busDirection: String?
    let startTime: String?
    let endTime: String?
    let term: Int?
}
