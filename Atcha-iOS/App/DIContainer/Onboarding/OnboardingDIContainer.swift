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
    private let locationService: LocationServiceProtocol
    private let locationStateHolder: LocationStateHolder
    
    init(apiService: APIService,
         locationService: LocationServiceProtocol,
         locationStateHolder: LocationStateHolder) {
        self.apiService = apiService
        self.locationService = locationService
        self.locationStateHolder = locationStateHolder
    }
    
    func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator {
        let homeRegiDIContainer = HomeRegisterDIContainer(apiService: apiService, locationStateHolder: locationStateHolder)
        let pushRegiDIContainer = PushRegisterDIContainer(apiService: apiService, locationStateHolder: locationStateHolder)
        return OnboardingCoordinator(apiService: apiService,
                                     navigationController: navigationController,
                                     locationHolder: locationStateHolder,
                                     homeDIConatiner: homeRegiDIContainer,
                                     pushRegisterDIContainer: pushRegiDIContainer)
    }
}
