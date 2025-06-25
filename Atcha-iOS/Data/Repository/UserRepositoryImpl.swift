//
//  UserRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

final class UserRepositoryImpl: UserRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func fetchUser() async throws -> UserInfo {
        return try await apiService.request(
            Endpoint(path: "https://atcha.p-e.kr/api/members/me",
                     method: .get)
        )
    }
}
