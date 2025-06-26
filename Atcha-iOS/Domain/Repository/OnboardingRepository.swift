//
//  OnboardingRepository.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation

protocol OnboardingRepository {
    // 회원 가입
    func signUp(_ request: SignUpRequest) async throws -> SignUpResponse
    
    // 주소 검색
    func searchLocation(_ request: SearchLocationRequest) async throws -> [Location]
    
    // 좌표 기반 주소 검색
    func reverseGeocodeLocation(_ request: ReverseGeocodeLocationRequest) async throws -> ReverseGeocodeLocationResponse
}
