//
//  ObserveLocationStreamUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation

protocol ObserveLocationStreamUseCase {
    func startUpdate() -> AsyncStream<CLLocation>
    func stopUpdate()
}

final class ObserLocationStreamUseCaseImpl: ObserveLocationStreamUseCase {
    private let repository: LocationStreamRepository
    
    init(repository: LocationStreamRepository) {
        self.repository = repository
    }
    
    func startUpdate() -> AsyncStream<CLLocation> {
        repository.observeLocationStream()
    }
    
    func stopUpdate() {
        repository.stopLocationUpdates()
    }
}
