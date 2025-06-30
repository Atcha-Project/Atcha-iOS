//
//  MapViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import Foundation
import CoreLocation

final class MapViewModel: BaseViewModel {
    @Published var currentLocation: CLLocation?
    
    private let requestUseCase: RequestLocationAuthorizationUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private var streamTask: Task<Void, Never>?
    
    init(requestUseCase: RequestLocationAuthorizationUseCase,
         streamUseCase: ObserveLocationStreamUseCase) {
        self.requestUseCase = requestUseCase
        self.streamUseCase = streamUseCase
    }
    
    func requestPermissionAndStartTracking() {
        Task {
            let status = await requestUseCase.askPermission()
            guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }

            streamTask = Task {
                for await location in streamUseCase.startUpdate() {
                    self.currentLocation = location
                }
            }
        }
    }

    func stopTracking() {
        streamTask?.cancel()
        streamUseCase.stopUpdate()
    }
}
