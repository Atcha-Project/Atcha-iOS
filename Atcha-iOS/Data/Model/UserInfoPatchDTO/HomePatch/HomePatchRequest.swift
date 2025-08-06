//
//  HomeModifyRequest.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/5/25.
//

import Foundation

struct HomePatchRequest: Codable {
    let address: String?
    let lat: Double?
    let lon: Double?
}
