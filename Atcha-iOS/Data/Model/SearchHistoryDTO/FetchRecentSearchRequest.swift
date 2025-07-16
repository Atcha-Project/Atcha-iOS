//
//  FetchRecentSearchRequest.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/14/25.
//

import Foundation

struct FetchRecentSearchRequest: Codable {
    let lat: Double?
    let lon: Double?

    init(lat: Double?, lon: Double?) {
        self.lat = lat
        self.lon = lon
    }
}
