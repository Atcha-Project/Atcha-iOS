//
//  RequestLocationAuthorizationRepository.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation

protocol PermissionRepository {
    func askPushPermission() async -> Bool 
    func askLocationPermission() async -> CLAuthorizationStatus
}
