//
//  User.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation
import CoreLocation

struct UserInfo {
    let id: Int?
    let providerId: String?
    let address: String?
    let coordinate: CLLocationCoordinate2D?
    let alarmFrequent: [Int?]
    let appVersion: String
}
