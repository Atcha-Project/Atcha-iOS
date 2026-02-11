//
//  SubwayRealTimeInfo.swift
//  Atcha-iOS
//
//  Created by wodnd on 2/11/26.
//

import Foundation

enum SubwayStatus: String, Decodable {
    case approaching = "APPROACHING"
    case arriving = "ARRIVING"
    case departed = "DEPARTED"
    case operating = "OPERATING"
    case waiting = "WAITING"
    case unknown

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SubwayStatus(rawValue: raw) ?? .unknown
    }
}

struct SubwayRealTimeInfo: Codable {
    let routeName: String?
    let subwayArrivalStatus: String?
    let remainingTime: Int?
    let isLast: Bool?
    let expectedArrivalTime: String?
    let trainNo: String?
    let destination: String?
    let direction: String?
}
