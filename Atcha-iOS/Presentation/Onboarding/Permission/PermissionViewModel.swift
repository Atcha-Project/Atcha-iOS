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
    private let authorizationRequestUseCase: RequestLocationAuthorizationUseCaseImpl
    
    init(authorizationRequestUseCase: RequestLocationAuthorizationUseCaseImpl) {
        self.authorizationRequestUseCase = authorizationRequestUseCase
    }
    
    func askLocationPermission() {
        Task {
            let status = await authorizationRequestUseCase.askLocationPermission()
            print("status : \(status)")
            askPushPermission()
        }
    }
    
    func askPushPermission() {
        Task {
            let _ = await authorizationRequestUseCase.askPushPermission()
            checkPermissionFinished = true
        }
    }
}
