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
                path: "https://atcha.p-e.kr/api/locations/rgeo",
                method: .get,
                parameters: [
                    "lat": "\(request.lat)",
                    "lon": "\(request.lon)" ]
            ))
    }
    
    func searchLoaction(request: SearchLocationRequest) async throws -> [SearchLocationResponse] {
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/locations",
                method: .get,
                parameters: [
                    "keyword": "\(request.keyword ?? "")",
                    "lat": "\(request.lat ?? 0.0)",
                    "lon": "\(request.lon ?? 0.0)"
                ]
            ))
    }
    
    func fetchRecentSearchHistories(request: FetchRecentSearchRequest) async throws -> [Location] {
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/locations/histories",
                method: .get,
                parameters: [
                    "lat": "\(request.lat ?? 0.0)",
                    "lon": "\(request.lon ?? 0.0)"
                ]
            )
        )
    }
    
    func addRecentSearchHistory(request: AddRecentSearchRequest) async throws -> EmptyResponse {
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/locations/histories", 
                method: .post,
                encoding: JSONEncoding.default,
            ),
            body: request
        )
    }
}


