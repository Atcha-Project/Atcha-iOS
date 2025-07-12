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
}
