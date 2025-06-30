//
//  RequestLocationAuthorizationUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation

protocol RequestLocationAuthorizationUseCase {
    func askPermission() async -> CLAuthorizationStatus
}

final class RequestLocationAuthorizationUseCaseImpl: RequestLocationAuthorizationUseCase {
    private let repository: RequestLocationAuthorizationRepository
    
    init(repository: RequestLocationAuthorizationRepository) {
        self.repository = repository
    }
    
    func askPermission() async -> CLAuthorizationStatus {
        return await repository.askPermission()
    }
}
