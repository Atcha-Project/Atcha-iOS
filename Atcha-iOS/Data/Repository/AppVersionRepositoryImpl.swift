//
//  AppVersionRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation

final class AppVersionRepositoryImpl: AppVersionRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func fetchAppVersion() async throws -> String {
        return try await apiService.request(
            Endpoint(path: "http://atcha.p-e.kr/api/app/version", method: .get)
        )
    }
}
