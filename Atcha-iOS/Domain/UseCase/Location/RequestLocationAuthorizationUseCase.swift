//
//  RequestLocationAuthorizationUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation

protocol RequestLocationAuthorizationUseCase {
    func askLocationPermission() async -> CLAuthorizationStatus
    func askPushPermission() async -> Bool
}

final class RequestLocationAuthorizationUseCaseImpl: RequestLocationAuthorizationUseCase {
    private let repository: PermissionRepositoryImpl
    
    init(repository: PermissionRepositoryImpl) {
        self.repository = repository
    }
    
    func askLocationPermission() async -> CLAuthorizationStatus {
        return await repository.askLocationPermission()
    }
    
    func askPushPermission() async -> Bool {
        return await repository.askPushPermission()
    }
}
