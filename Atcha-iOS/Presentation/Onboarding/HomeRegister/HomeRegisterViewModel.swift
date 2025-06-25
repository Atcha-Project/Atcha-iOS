//
//  HomeRegisterViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import Foundation

final class HomeRegisterViewModel: BaseViewModel {
    let onboardingUseCase: OnboardingUseCase
    
    init(onboardingUseCase: OnboardingUseCase) {
        self.onboardingUseCase = onboardingUseCase
    }
    
    func makeSearchLocationViewModel() -> SearchLocationViewModel {
        return SearchLocationViewModel(onboardingUseCase: onboardingUseCase)
    }
}
