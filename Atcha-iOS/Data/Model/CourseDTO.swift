//
//  CourseDTO.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/3/25.
//

import Foundation

struct Course: Codable, Hashable {
    let routedId: String?
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
    let type: Int?
    let service: Int?
    let start: addressInfo
    let end: addressInfo
    let passStopList: [passStopList]
    let step: [step]
    let passShape: String
}

struct addressInfo: Codable, Hashable{
    let name: String?
    let lon: String?
    let lan: String?
}

struct passStopList: Codable, Hashable {
    let index: Int?
    let stationId: Int?
    let stationName: String?
    let lon: String?
    let lan: String?
}

struct step: Codable, Hashable{
    let streetName: String?
    let distance: Int?
    let description: String?
    let linestring: String?
}
