//
//  RequestLocationAuthorizationRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation

final class RequestLocationAuthorizationRepositoryImpl: RequestLocationAuthorizationRepository {
    func askPermission() async -> CLAuthorizationStatus {
        let manager = CLLocationManager()
        return await withCheckedContinuation { continuation in
            manager.requestWhenInUseAuthorization()
            continuation.resume(returning: manager.authorizationStatus)
        }
    }
}
