//
//  FetchTaxiFareRequest.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/26/25.
//

import Foundation

struct FetchTaxiFareRequest: Codable {
    let originLat: Double?
    let originLon: Double?
    let destinationLat: Double?
    let destinationLon: Double?
    
    enum CodingKeys: String, CodingKey {
        case originLat = "startLat"
        case originLon = "startLon"
        case destinationLat = "endLat"
        case destinationLon = "endLon"
    }
}
