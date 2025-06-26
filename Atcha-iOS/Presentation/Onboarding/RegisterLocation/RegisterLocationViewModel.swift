//
//  RegisterLocationViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/26/25.
//

import Foundation

final class RegisterLocationViewModel: BaseViewModel {
    private let onboardingUseCase: OnboardingUseCase
    
    init(onboardingUseCase: OnboardingUseCase) {
        self.onboardingUseCase = onboardingUseCase
    }
    
    func reverseGeocodeLocation(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await onboardingUseCase.reverseGeocodeLocation(request)
    }
}
