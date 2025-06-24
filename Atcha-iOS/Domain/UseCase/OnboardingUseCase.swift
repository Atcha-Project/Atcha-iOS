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
    func searchLocation(_ request: SearchLocationRequest) async throws -> SearchLocationResponse
}

final class OnboardingUseCaseImpl: OnboardingUseCase {
    private let repository: OnboardingRepository
    
    init(repository: OnboardingRepository) {
        self.repository = repository
    }
    
    func signUp(_ request: SignUpRequest) async throws -> SignUpResponse {
        
        return try await repository.signUp(request)
        
    }
    
    func searchLocation(_ request: SearchLocationRequest) async throws -> SearchLocationResponse {
        
        return try await repository.searchLocation(request)
    }
}
