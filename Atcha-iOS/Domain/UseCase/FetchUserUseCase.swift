//
//  FetchUserUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

final class UserUseCase {
    private let repositoy: UserRepository
    
    init(repositoy: UserRepository) {
        self.repositoy = repositoy
    }
    
    func fetchUser() async throws -> User {
        try await repositoy.fetchUser()
    }
}
