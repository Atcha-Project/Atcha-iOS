//
//  UserRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

final class UserRepositoryImpl: UserRepository {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func fetchUser() async throws -> User {
        return .init(id: 1, nickname: "")
    }
}
