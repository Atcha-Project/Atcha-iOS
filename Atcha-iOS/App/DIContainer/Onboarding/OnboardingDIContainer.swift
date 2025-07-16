//
//  OnboardingDIContainer.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import UIKit
import Foundation

final class OnboardingDIContainer {
    private let apiService: APIService
    private let homeRegisterDIConatiner: HomeRegisterDIContainer
    private let pushRegisterDIContainer: PushRegisterDIContainer
    //    private let locationService: LocationServiceProtocol
    private let locationStateHolder: LocationStateHolder
    private let permissionDIContainer: PermissionDIContainer
    
    init(apiService: APIService,
         locationStateHolder: LocationStateHolder,
         homeRegisterDIConatiner: HomeRegisterDIContainer,
         pushRegisterDIContainer: PushRegisterDIContainer,
         permissionDIContainer: PermissionDIContainer) {
        self.apiService = apiService
        self.homeRegisterDIConatiner = homeRegisterDIConatiner
        self.pushRegisterDIContainer = pushRegisterDIContainer
        self.locationStateHolder = locationStateHolder
        self.permissionDIContainer = permissionDIContainer
    }
    
    func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator {
        return OnboardingCoordinator(apiService: apiService,
                                     navigationController: navigationController,
                                     locationHolder: locationStateHolder,
                                     homeDIConatiner: homeRegisterDIConatiner,
                                     pushRegisterDIContainer: pushRegisterDIContainer, permissionDIConatiner: permissionDIContainer)
    }
}
