//
//  OnboardingUseCase.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation
import CoreLocation

protocol OnboardingUseCase {
    // 회원가입
    func signUp(_ request: SignUpRequest) async throws -> SignUpResponse
    
    // 주소 검색
    func searchLocation(_ request: SearchLocationRequest) async throws -> [Location]
    
    // 좌표 기반 주소 검색
    func reverseGeocodeLocation(_ request: ReverseGeocodeLocationRequest) async throws -> ReverseGeocodeLocationResponse
    
    // 현위치 좌표 찾기
    func requestCurrentLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void)
}

final class OnboardingUseCaseImpl: OnboardingUseCase {
    private let repository: OnboardingRepository
    private let locationService: LocationServiceProtocol
    
    init(repository: OnboardingRepository, locationService: LocationServiceProtocol) {
        self.repository = repository
        self.locationService = locationService
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
    
    // 현위치 좌표 찾기
    func requestCurrentLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        locationService.requestLocation(completion: completion)
    }
}
