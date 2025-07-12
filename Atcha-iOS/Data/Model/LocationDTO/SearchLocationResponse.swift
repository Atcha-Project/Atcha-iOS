//
//  SearchLocationResponse.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/12/25.
//

import Foundation

struct SearchLocationResponse: Codable {
    let name: String?
    let lat: Double?
    let lon: Double?
    let businessCategory: String?
    let address: String?
    let radius: String?
}

extension SearchLocationResponse {
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
            address: address
        )
    }
}
