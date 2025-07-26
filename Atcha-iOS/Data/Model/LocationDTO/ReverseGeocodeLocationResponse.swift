//
//  ReverseGeocodeLocationResponse.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/26/25.
//

import Foundation

struct ReverseGeocodeLocationResponse: Codable {
    let name: String?
    let address: String?
    let lat: Double?
    let lon: Double?
}

extension ReverseGeocodeLocationResponse {
    func toEntity() -> Location? {
        guard
            let name = name,
            let lat = lat,
            let lon = lon,
            let address = address
        else {
            return nil
        }
        
        return Location(
            name: name,
            lat: lat,
            lon: lon,
            businessCategory: nil,
            address: address,
            radius: nil
        )
    }
}
