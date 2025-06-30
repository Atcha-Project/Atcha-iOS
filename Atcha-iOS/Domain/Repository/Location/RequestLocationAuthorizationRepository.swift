//
//  RequestLocationAuthorizationRepository.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation

protocol RequestLocationAuthorizationRepository {
    func askPermission() async -> CLAuthorizationStatus
}
