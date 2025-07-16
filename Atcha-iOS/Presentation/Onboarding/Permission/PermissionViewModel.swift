//
//  PermissionViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/15/25.
//

import Foundation
import UIKit
import CoreLocation

final class PermissionViewModel: BaseViewModel {
    @Published var checkPermissionFinished: Bool = false
    
    private var streamTask: Task<Void, Never>?
    
    private let authorizationRequestUseCase: RequestLocationAuthorizationUseCase
    private let streamUseCase: ObserveLocationStreamUseCase
    private let locationStateHolder: LocationStateHolder
    
    init(authorizationRequestUseCase: RequestLocationAuthorizationUseCase,
         streamUseCase: ObserveLocationStreamUseCase,
         locationStateHolder: LocationStateHolder) {
        self.authorizationRequestUseCase = authorizationRequestUseCase
        self.streamUseCase = streamUseCase
        self.locationStateHolder = locationStateHolder
    }
    
    func askLocationPermission() {
        Task {
            let status = await authorizationRequestUseCase.askLocationPermission()
            print("status : \(status)")
            askPushPermission()
        }
    }
    
    private func askPushPermission() {
        Task {
            let _ = await authorizationRequestUseCase.askPushPermission()
            requestMyLocation()
        }
    }
    
    private func requestMyLocation() {
        Task {
            streamTask = Task {
                for await location in streamUseCase.startUpdate() {
                    let currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                                                         longitude: location.coordinate.longitude)
                    locationStateHolder.currentLocationSubject.send(currentLocation)
                    checkPermissionFinished = true
                    break
                }
            }
        }
    }
}
