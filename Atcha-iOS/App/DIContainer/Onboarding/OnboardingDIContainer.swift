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
    
    init(apiService: APIService, locationService: LocationServiceProtocol) {
        self.apiService = apiService
        self.locationService = locationService
    }
    
    func makeOnboardingUseCase() -> OnboardingUseCase {
        let repository: OnboardingRepository = OnboardingRepositoryImpl(apiService: apiService)
        
        return OnboardingUseCaseImpl(repository: repository, locationService: locationService)
    }
    
    func makeHomeRegisterViewModel() -> HomeRegisterViewModel {
        HomeRegisterViewModel(onboardingUseCase: makeOnboardingUseCase())
    }
    
    func makeSearchLocationViewModel() -> SearchLocationViewModel {
        SearchLocationViewModel(onboardingUseCase: makeOnboardingUseCase())
    }
    
    func makePushAlarmViewModel() -> PushAlarmViewModel {
        PushAlarmViewModel(onboardingUseCase: makeOnboardingUseCase())
    }
    
    func makeRegisterLocationViewModel() -> RegisterLocationViewModel {
        RegisterLocationViewModel(onboardingUseCase: makeOnboardingUseCase())
    }
    
    func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator {
        OnboardingCoordinator(navigationController: navigationController, disContainer: self)
    }
}
