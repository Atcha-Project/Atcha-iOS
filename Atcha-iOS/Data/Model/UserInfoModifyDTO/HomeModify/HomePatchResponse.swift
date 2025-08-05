//
//  HomeModifyResponse.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/5/25.
//

import Foundation

struct HomePatchResponse: Codable {
    let id: Int?
    let providerId: String?
    let address: String?
    let lat: Double?
    let lon: Double?
    let alertFrequencies: [Int]?
}
