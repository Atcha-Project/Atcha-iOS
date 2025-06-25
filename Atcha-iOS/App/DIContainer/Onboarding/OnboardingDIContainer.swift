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
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func makeOnboardingUseCase() -> OnboardingUseCase {
        let repository: OnboardingRepository = OnboardingRepositoryImpl(apiService: apiService)
        
        return OnboardingUseCaseImpl(repository: repository)
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
    
    func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator {
        
        OnboardingCoordinator(navigationController: navigationController, disContainer: self)
    }
}
