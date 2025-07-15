//
//  AddRecentSearchHistoryRequest.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/14/25.
//

import Foundation

struct AddRecentSearchRequest: Codable {
    let name: String?
    let lat: Double?
    let lon: Double?
    let businessCategory: String?
    let address: String?

    init(name: String?, lat: Double?, lon: Double?, businessCategory: String?, address: String?) {
        self.name = name
        self.lat = lat
        self.lon = lon
        self.businessCategory = businessCategory
        self.address = address
    }

    init(lat: Double?, lon: Double?, businessCategory: String?, address: String?) {
        self.name = nil
        self.lat = lat
        self.lon = lon
        self.businessCategory = businessCategory
        self.address = address
    }
}
