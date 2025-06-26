//
//  SearchLocationViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import Foundation

final class SearchLocationViewModel: BaseViewModel {
    let onboardingUseCase: OnboardingUseCase
    
    var onLocationsUpdated: (([Location]) -> Void)?
    
    init(onboardingUseCase: OnboardingUseCase) {
        self.onboardingUseCase = onboardingUseCase
    }
    
    @MainActor
    func searchLocation(keyword: String, lat: Double, lon: Double) {
        Task {
            do {
                let request = SearchLocationRequest(keyword: keyword, lat: lat, lon: lon)
                let response = try await onboardingUseCase.searchLocation(request)
                
                DispatchQueue.main.async {
                    self.onLocationsUpdated?(response)
                }
            } catch {
                print("장소 검색 실패")
            }
        }
    }
    
    func reverseGeocodeLocation(lat: Double, lon: Double) async throws -> ReverseGeocodeLocationResponse {
        let request = ReverseGeocodeLocationRequest(lat: lat, lon: lon)
        return try await onboardingUseCase.reverseGeocodeLocation(request)
    }
    
    func makeRegisterLocationViewModel() -> RegisterLocationViewModel {
        return RegisterLocationViewModel(onboardingUseCase: onboardingUseCase)
    }
}
