//
//  SearchAddressUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/3/25.
//

import Foundation
import CoreLocation

protocol SearchAddressUseCase {
    func searchLocation(_ request: ReverseGeocodeLocationRequest) async throws -> Location?
    
    func searchAddress(_ request: SearchLocationRequest) async throws -> [Location]
    
    // 최근 검색 조회
    func fetchRecentSearchHistories(_ request: FetchRecentSearchRequest) async throws -> [Location]
    
    // 최근 검색 추가
    func addRecentSearchHistory(_ request: RecentSearchRequest) async throws -> APIEmptyResponse
    
    // 최근 검색 전체 삭제
    func clearAllSearchHistories() async throws -> APIEmptyResponse
    
    // 최근 검색 삭제
    func deleteSearchHistory(_ request: RecentSearchRequest) async throws -> APIEmptyResponse
}

final class SearchAddressUseCaseImpl: SearchAddressUseCase {
    private let repository: AddressRepository
    init(repository: AddressRepository) {
        self.repository = repository
    }
    
    func searchLocation(_ request: ReverseGeocodeLocationRequest) async throws -> Location? {
        return try await repository.fetchCurrentLocation(request: request).toEntity()
    }
    
    func searchAddress(_ request: SearchLocationRequest) async throws -> [Location] {
        return try await repository.searchLoaction(request: request).compactMap { $0.toEntity() }
    }
    
    func fetchRecentSearchHistories(_ request: FetchRecentSearchRequest) async throws -> [Location] {
        return try await repository.fetchRecentSearchHistories(request: request).compactMap { $0.toEntity() }
    }
    
    func addRecentSearchHistory(_ request: RecentSearchRequest) async throws -> APIEmptyResponse{
        return try await repository.addRecentSearchHistory(request: request)
    }
    
    func clearAllSearchHistories() async throws -> APIEmptyResponse {
        return try await repository.clearAllSearchHistories()
    }
    
    func deleteSearchHistory(_ request: RecentSearchRequest) async throws -> APIEmptyResponse {
        return try await repository.deleteSearchHistory(request: request)
    }
}
