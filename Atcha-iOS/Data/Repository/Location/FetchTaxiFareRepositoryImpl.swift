//
//  FetchTaxiFareRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/7/25.
//

import Foundation
import Alamofire

final class FetchTaxiFareRepositoryImpl: FetchTaxiFareRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func fetchTaxiFare(request: FetchTaxiFareRequest) async throws -> Double {
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/transits/taxi-fare",
                method: .get,
                parameters: request.toDictionary()
            )
        )
    }
}
