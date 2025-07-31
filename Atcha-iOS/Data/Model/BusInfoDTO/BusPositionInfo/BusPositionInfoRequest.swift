//
//  BusPositionInfoRequest.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation

struct BusPositionInfoRequest: Codable {
    let busRouteId: String?
    let routeName: String?
    let serviceRegion: String?
}
