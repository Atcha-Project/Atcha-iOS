//
//  SearchAddressUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/3/25.
//

import Foundation
import CoreLocation

protocol SearchAddressUseCase {
    func searchLocation(_ request: ReverseGeocodeLocationRequest) async throws -> ReverseGeocodeLocationResponse
    func searchAddress(_ request: SearchLocationRequest) async throws -> [Location]
    
    // 최근 검색 기록 관련
    func fetchRecentSearchHistories(_ request: FetchRecentSearchRequest) async throws -> [Location]
    func addRecentSearchHistory(_ request: AddRecentSearchRequest) async throws -> EmptyResponse
//    func clearAllSearchHistories()
//    func deleteSearchHistory()
}

final class SearchAddressUseCaseImpl: SearchAddressUseCase {
    private let repository: AddressRepository
    init(repository: AddressRepository) {
        self.repository = repository
    }
    
    func searchLocation(_ request: ReverseGeocodeLocationRequest) async throws -> ReverseGeocodeLocationResponse {
        return try await repository.fetchCurrentLocation(request: request)
    }
    
    func searchAddress(_ request: SearchLocationRequest) async throws -> [Location] {
        return try await repository.searchLoaction(request: request).compactMap { $0.toEntity() }
    }
    
    func fetchRecentSearchHistories(_ request: FetchRecentSearchRequest) async throws -> [Location] {
        return try await repository.fetchRecentSearchHistories(request: request)
    }
    
    func addRecentSearchHistory(_ request: AddRecentSearchRequest) async throws -> EmptyResponse{
        return try await repository.addRecentSearchHistory(request: request)
    }
}
