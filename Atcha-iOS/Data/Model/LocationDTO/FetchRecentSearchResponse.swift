//
//  FetchRecentSearchResponse.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/17/25.
//

import Foundation

struct FetchRecentSearchResponse: Codable {
    let name: String?
    let lat: Double?
    let lon: Double?
    let businessCategory: String?
    let address: String?
    let radius: String?
}

extension FetchRecentSearchResponse {
    func toEntity() -> Location? {
        guard
            let name = name,
            let lat = lat,
            let lon = lon,
            let businessCategory = businessCategory,
            let address = address,
            let radius = radius
        else {
            return nil
        }
        
        return Location(
            name: name,
            lat: lat,
            lon: lon,
            businessCategory: businessCategory,
            address: address,
            radius: radius
        )
    }
}
