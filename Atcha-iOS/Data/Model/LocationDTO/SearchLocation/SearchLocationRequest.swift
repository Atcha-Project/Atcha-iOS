//
//  SearchLocationRequest.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/12/25.
//

import Foundation

struct SearchLocationRequest: Codable {
    let keyword: String?
    let lat: Double?
    let lon: Double?

    init(keyword: String?, lat: Double?, lon: Double?) {
        self.keyword = keyword
        self.lat = lat
        self.lon = lon
    }

    init(lat: Double?, lon: Double?) {
        self.keyword = nil
        self.lat = lat
        self.lon = lon
    }
}
