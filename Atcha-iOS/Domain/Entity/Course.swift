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
    let legs: [legs]
}

struct legs: Codable, Hashable {
    let distance: Int?
    let sectionTime: Int?
    let mode: String?
    let departureDateTime: String?
    let route: String?
    let type: String?
    let service: String?
    let start: addressInfo?
    let end: addressInfo?
    let passStopList: [passStopList]?
    let step: [step]?
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

struct step: Codable, Hashable{
    let streetName: String?
    let distance: Double?
    let description: String?
    let linestring: String?
}

enum TransportMode: String {
    case walk = "WALK"
    case bus = "BUS"
    case subway = "SUBWAY"
    case unknown
}

extension legs {
    var modeEnum: TransportMode {
        return TransportMode(rawValue: mode?.uppercased() ?? "") ?? .unknown
    }
}
