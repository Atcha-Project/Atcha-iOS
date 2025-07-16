//
//  AddressRepository.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/3/25.
//

import Foundation
import CoreLocation

protocol AddressRepository {
    func fetchCurrentLocation(request: ReverseGeocodeLocationRequest) async throws -> ReverseGeocodeLocationResponse
    func searchLoaction(request: SearchLocationRequest) async throws -> [SearchLocationResponse]
    func fetchRecentSearchHistories(request: FetchRecentSearchRequest) async throws -> [Location]
    func addRecentSearchHistory(request: RecentSearchRequest) async throws -> APIEmptyResponse
    func clearAllSearchHistories() async throws -> APIEmptyResponse
    func deleteSearchHistory(request: RecentSearchRequest) async throws -> APIEmptyResponse
}
