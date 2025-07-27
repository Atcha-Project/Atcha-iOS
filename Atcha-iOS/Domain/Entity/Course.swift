//
//  Course.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/17/25.
//

import Foundation

struct Course: Codable, Hashable {
    let routeId: String?
    let departureDateTime: String?
    let totalTime: Int?
    let totalWalkTime: Int?
    let transferCount: Int?
    let totalDistance: Int?
    let totalWalkDistance: Int?
    let pathType: Int?
    let legs: [Legs]
}

struct Legs: Codable, Hashable {
    let distance: Int?
    let sectionTime: Int?
    let mode: TransportMode?
    let departureDateTime: String?
    let route: String?
    let type: String?
    let service: String?
    let start: addressInfo?
    let end: addressInfo?
    let passStopList: [passStopList]?
    let step: [Step]?
    let passShape: String?
}

struct addressInfo: Codable, Hashable{
    let name: String?
    let lon: Double?
    let lan: Double?
}

struct passStopList: Codable, Hashable {
    let index: Int?
    let stationName: String?
    let lon: String?
    let lan: String?
}

struct Step: Codable, Hashable{
    let streetName: String?
    let distance: Double?
    let description: String?
    let linestring: String?
}

enum TransportMode: String, Codable {
    case walk = "WALK"
    case bus = "BUS"
    case subway = "SUBWAY"
    case unknown

    func icon(for routeType: String) -> String? {
        switch self {
        case .bus:
            return TransportMode.busIcon[routeType]
        case .subway:
            return TransportMode.subwayIcon[routeType]
        default:
            return nil
        }
    }

    func getOffIcon(for routeType: String) -> String? {
        switch self {
        case .bus:
            return TransportMode.busGetOffIcon[routeType]
        case .subway:
            return TransportMode.subwayGetOffIcon[routeType]
        default:
            return nil
        }
    }
}

struct LegPathInfo {
    let mode: TransportMode?
    let step: [Step]?
    let passShape: String?
}

