//
//  Location.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/12/25.
//

import Foundation

struct Location: Codable, Equatable {
    let name: String?
    let lat: Double
    let lon: Double
    let address: String?
}
