//
//  AddressRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/3/25.
//

import Foundation
import Alamofire

final class AddressRepositoryImpl: AddressRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func fetchCurrentLocation(request: ReverseGeocodeLocationRequest) async throws -> ReverseGeocodeLocationResponse {
        return try await apiService.request(
            Endpoint(
                path: "/locations/rgeo",
                method: .get,
                parameters: [
                    "lat": "\(request.lat)",
                    "lon": "\(request.lon)" ]
            ))
    }
    
    func searchLoaction(request: SearchLocationRequest) async throws -> [SearchLocationResponse] {
        return try await apiService.request(
            Endpoint(
                path: "/locations",
                method: .get,
                parameters: [
                    "keyword": "\(request.keyword ?? "")",
                    "lat": "\(request.lat ?? 0.0)",
                    "lon": "\(request.lon ?? 0.0)"
                ]
            ))
    }
    
    func fetchRecentSearchHistories(request: FetchRecentSearchRequest) async throws -> [FetchRecentSearchResponse] {
        return try await apiService.request(
            Endpoint(
                path: "/locations/histories",
                method: .get,
                parameters: [
                    "lat": "\(request.lat ?? 0.0)",
                    "lon": "\(request.lon ?? 0.0)"
                ]
            )
        )
    }
    
    func addRecentSearchHistory(request: RecentSearchRequest) async throws -> APIEmptyResponse {
        return try await apiService.request(
            Endpoint(
                path: "/locations/histories",
                method: .post,
                encoding: JSONEncoding.default
            ),
            body: request)
    }
    
    func clearAllSearchHistories() async throws -> APIEmptyResponse {
        return try await apiService.request(
            Endpoint(
                path: "/locations/histories",
                method: .delete
            )
        )
    }
    
    func deleteSearchHistory(request: RecentSearchRequest) async throws -> APIEmptyResponse {
        return try await apiService.request(
            Endpoint(
                path: "/locations/history",
                method: .delete,
                parameters: [
                    "name": "\(request.name ?? "")",
                    "lat": "\(request.lat ?? 0.0)",
                    "lon": "\(request.lon ?? 0.0)",
                    "businessCategory": "\(request.businessCategory ?? "")",
                    "address": "\(request.address ?? "")"
                ]
            )
        )
    }
    
    func checkServiceRegion(request: CheckServiceRegionRequest) async throws -> Bool {
        return try await apiService.request(
            Endpoint(
                path: "/locations/is-service-region",
                method: .get,
                parameters: [
                    "lat": "\(request.lat ?? 0.0)",
                    "lon": "\(request.lon ?? 0.0)"
                ]
            )
        )
    }
}


