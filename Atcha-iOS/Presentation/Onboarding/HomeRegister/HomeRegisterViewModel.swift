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
    
    func makeRegisterLocationViewModel() -> RegisterLocationViewModel {
        return RegisterLocationViewModel(onboardingUseCase: onboardingUseCase)
    }
    
    func reverseGeocodeLocation(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await onboardingUseCase.reverseGeocodeLocation(request)
    }
}
