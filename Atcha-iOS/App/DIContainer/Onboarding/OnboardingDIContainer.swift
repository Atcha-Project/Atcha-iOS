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
    private let locationService: LocationServiceProtocol
    private let locationStateHolder: LocationStateHolder
    
    init(apiService: APIService,
         locationService: LocationServiceProtocol,
         locationStateHolder: LocationStateHolder,
         homeRegisterDIConatiner: HomeRegisterDIContainer,
         pushRegisterDIContainer: PushRegisterDIContainer) {
        self.apiService = apiService
        self.homeRegisterDIConatiner = homeRegisterDIConatiner
        self.pushRegisterDIContainer = pushRegisterDIContainer
        self.locationService = locationService
        self.locationStateHolder = locationStateHolder
    }
    
    func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator {
        return OnboardingCoordinator(apiService: apiService,
                                     navigationController: navigationController,
                                     locationHolder: locationStateHolder,
                                     homeDIConatiner: homeRegisterDIConatiner,
                                     pushRegisterDIContainer: pushRegisterDIContainer)
    }
}
