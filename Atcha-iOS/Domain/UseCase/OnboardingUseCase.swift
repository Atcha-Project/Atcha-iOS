//
//  OnboardingUseCase.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation

protocol OnboardingUseCase {
    // 회원가입
    func signUp(_ request: SignUpRequest) async throws -> SignUpResponse
    
    // 주소 검색
    func searchLocation(_ request: SearchLocationRequest) async throws -> [Location]
    
    // 좌표 기반 주소 검색
    func reverseGeocodeLocation(_ request: ReverseGeocodeLocationRequest) async throws -> ReverseGeocodeLocationResponse
}

final class OnboardingUseCaseImpl: OnboardingUseCase {
    private let repository: OnboardingRepository
    
    init(repository: OnboardingRepository) {
        self.repository = repository
    }
    
    func signUp(_ request: SignUpRequest) async throws -> SignUpResponse {
        
        return try await repository.signUp(request)
        
    }
    
    // 장소 검색을 통한 위치 찾기
    func searchLocation(_ request: SearchLocationRequest) async throws -> [Location] {
        
        return try await repository.searchLocation(request)
    }
    
    // 현위치 좌표를 통한 위치 찾기
    func reverseGeocodeLocation(_ request: ReverseGeocodeLocationRequest) async throws -> ReverseGeocodeLocationResponse {
        return try await repository.reverseGeocodeLocation(request)
    }
}
