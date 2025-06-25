//
//  User.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

struct UserInfo: Decodable {
    let id: Int?
    let providerId: String?
    let nickname: String?
    let profileUrl: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let alarmFrequent: [Int?]

    enum CodingKeys: String, CodingKey {
        case id
        case providerId
        case nickname
        case profileUrl = "profileImageUrl"
        case address
        case latitude = "lat"
        case longitude = "lon"
        case alarmFrequent = "alertFrequencies"
    }
}
