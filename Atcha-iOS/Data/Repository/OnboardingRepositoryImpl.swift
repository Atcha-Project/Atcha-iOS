//
//  OnboardingRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation

final class OnboardingRepositoryImpl: OnboardingRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func signUp(_ request: SignUpRequest) async throws -> SignUpResponse {
        
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/auth/sign-up",
                method: .post,
                headers: ["Authorization": "Bearer "]),
            body: request)
    }
    
    func searchLocation(_ request: SearchLocationRequest) async throws -> [Location] {
        
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/locations",
                method: .get,
                parameters: [
                    "keyword": "\(request.keyword)",
                    "lat": "\(request.lat)",
                    "lon": "\(request.lon)" ]
            ))
    }
}
