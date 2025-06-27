//
//  OnboardingRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation
import Alamofire

final class OnboardingRepositoryImpl: OnboardingRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func signUp(_ request: SignUpRequest) async throws -> SignUpResponse {
        
        guard let providerToken = UserDefaultsWrapper().string(forKey: UserDefaultsWrapper.Key.providerToken.rawValue) else {
            print("플랫폼 토큰 없음")
            throw NSError(domain: "SignUpError", code: -1, userInfo: [NSLocalizedDescriptionKey: "플랫폼 토큰 없음"])
        }
        
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/auth/sign-up",
                method: .post,
                encoding: JSONEncoding.default,
                headers: ["Authorization": "Bearer \(providerToken)"]),
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
    
    func reverseGeocodeLocation(_ request: ReverseGeocodeLocationRequest) async throws -> ReverseGeocodeLocationResponse {
        
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/locations/rgeo",
                method: .get,
                parameters: [
                    "lat": "\(request.lat)",
                    "lon": "\(request.lon)" ]
            ))
    }
}
