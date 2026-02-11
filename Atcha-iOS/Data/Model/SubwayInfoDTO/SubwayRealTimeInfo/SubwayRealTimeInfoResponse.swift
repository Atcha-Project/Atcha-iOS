//
//  BusRealTimeInfoResponse.swift
//  Atcha-iOS
//
//  Created by wodnd on 2/11/26.
//

import Foundation

struct SubwayRealTimeInfoResponse: Codable {
    let routeName: String?
    let subwayArrivalStatus: String?
    let remainingTime: Int?
    let isLast: Bool?
    let expectedArrivalTime: String?
    let trainNo: String?
    let destination: String?
    let direction: String?
}

extension SubwayRealTimeInfoResponse {
    func toEntity() -> SubwayRealTimeInfo? {
        guard
            let routeName,
            let subwayArrivalStatus,
            let remainingTime,
            let isLast,
            let expectedArrivalTime,
            let trainNo,
            let destination,
            let direction
        else { return nil }

        return SubwayRealTimeInfo(
            routeName: routeName,
            subwayArrivalStatus: subwayArrivalStatus,
            remainingTime: remainingTime,
            isLast: isLast,
            expectedArrivalTime: expectedArrivalTime,
            trainNo: trainNo,
            destination: destination,
            direction: direction
        )
    }
}
