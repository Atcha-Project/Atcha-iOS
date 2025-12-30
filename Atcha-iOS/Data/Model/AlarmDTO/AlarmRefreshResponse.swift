//
//  AlarmRefreshResponse.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/8/25.
//

import Foundation

struct AlarmRefreshResponse: Codable {
    let departureTime: String?
    let updatedAt: String?
    let lastRouteId: String?
    let isReal: Bool?
}

extension AlarmRefreshResponse {
    func toEntity() -> AlarmRefresh? {
        return AlarmRefresh(
            departureTime: departureTime,
            updatedAt: updatedAt,
            lastRouteId: lastRouteId,
            isReal: isReal
        )
    }
}
