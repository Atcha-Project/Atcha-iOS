//
//  BusOperationResponse.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation

struct BusOperationInfoResponse: Codable {
    let startStationName: String?
    let endStationName: String?
    let serviceHours: [ServiceHoursResponse]?
}

struct ServiceHoursResponse: Codable {
    let dailyType: String?
    let busDirection: String?
    let startTime: String?
    let endTime: String?
    let term: Int?
}


extension BusOperationInfoResponse {
    func toEntity() -> BusOperationInfo? {
        guard
            let startStationName = startStationName,
            let endStationName = endStationName,
            let serviceHours = serviceHours
        else {
            return nil
        }
        
        return BusOperationInfo(
            startStationName: startStationName,
            endStationName: endStationName,
            serviceHours: serviceHours.compactMap { $0.toEntity() }
        )
    }
}

extension ServiceHoursResponse {
    func toEntity() -> ServiceHours? {
        guard
            let dailyType = dailyType,
            let busDirection = busDirection,
            let startTime = startTime,
            let endTime = endTime,
            let term = term
        else {
            return nil
        }
        
        return ServiceHours(
            dailyType: dailyType,
            busDirection: busDirection,
            startTime: startTime,
            endTime: endTime,
            term: term
        )
    }
}
