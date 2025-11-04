//
//  AppVersionRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation
import Alamofire

final class AppVersionRepositoryImpl: AppVersionRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func fetchAppVersion() async throws -> String {
        return try await apiService.request(
            Endpoint(path: "/app/version",
                     method: .get,
                     headers: ["X-Platform" : "iOS"])
        )
    }
    
    func updateAppVersion(version: AppVersionRequest) async throws -> APIEmptyResponse {
        return try await apiService.request(
            Endpoint(path: "/app/version",
                     method: .post,
                     encoding: JSONEncoding.default,
                     headers: ["X-Platform" : "iOS"]),
            body: version
        )
    }
}
