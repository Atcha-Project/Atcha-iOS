//
//  CourseSearchResponse.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/17/25.
//

import Foundation

struct CourseSearchResponse: Codable {
    let routeId: String?
    let departureDateTime: String?
    let totalTime: Int?
    let totalWalkTime: Int?
    let transferCount: Int?
    let totalDistance: Int?
    let totalWalkDistance: Int?
    let pathType: Int?
    let legs: [LegResponse]?
    
    func toEntity() -> Course {
        return Course(
            routeId: routeId,
            departureDateTime: departureDateTime,
            totalTime: totalTime,
            totalWalkTime: totalWalkTime,
            transferCount: transferCount,
            totalDistance: totalDistance,
            totalWalkDistance: totalWalkDistance,
            pathType: pathType,
            legs: legs?.map { $0.toEntity() } ?? []
        )
    }
}

struct LegResponse: Codable {
    let distance: Int?
    let sectionTime: Int?
    let mode: String?
    let departureDateTime: String?
    let route: String?
    let type: String?
    let service: String?
    let start: AddressInfoResponse?
    let end: AddressInfoResponse?
    let passStopList: [PassStopResponse]?
    let step: [StepResponse]?
    let passShape: String?
    
    func toEntity() -> legs {
        return legs(
            distance: distance,
            sectionTime: sectionTime,
            mode: mode,
            departureDateTime: departureDateTime,
            route: route,
            type: type,
            service: service,
            start: start?.toEntity(),
            end: end?.toEntity(),
            passStopList: passStopList?.map { $0.toEntity() },
            step: step?.map { $0.toEntity() },
            passShape: passShape
        )
    }
}

struct AddressInfoResponse: Codable {
    let name: String?
    let lon: Double?
    let lan: Double?
    
    func toEntity() -> addressInfo {
        return addressInfo(name: name, lon: lon, lan: lan)
    }
}

struct PassStopResponse: Codable {
    let index: Int?
    let stationName: String?
    let lon: String?
    let lan: String?
    
    func toEntity() -> passStopList {
        return passStopList(index: index, stationName: stationName, lon: lon, lan: lan)
    }
}

struct StepResponse: Codable {
    let streetName: String?
    let distance: Double?
    let description: String?
    let linestring: String?
    
    func toEntity() -> step {
        return step(streetName: streetName, distance: distance, description: description, linestring: linestring)
    }
}
