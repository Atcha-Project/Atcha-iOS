//
//  UserInfoResponse.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import Foundation
import CoreLocation

struct UserInfoResponse: Codable {
    let id: Int?
    let providerId: String?
    let nickname: String?
    let profileUrl: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let alarmFrequent: [Int?]
    let appVersion: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case providerId
        case nickname
        case profileUrl
        case address
        case latitude = "lat"
        case longitude = "lon"
        case alarmFrequent = "alertFrequencies"
        case appVersion
    }
}

extension UserInfoResponse {
    func toEntity() -> UserInfo? {
        guard let latitude, let longitude else { return nil }
        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude,
                                                                        longitude: longitude)
        return UserInfo(id: id,
                        providerId: providerId,
                        address: address,
                        coordinate: coordinate,
                        alarmFrequent: alarmFrequent, appVersion: appVersion)
    }
}
