//
//  FetchUserUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

protocol FetchUserUseCase {
    func excute() async throws -> UserInfo?
}

final class FetchUserUseCaseImpl: FetchUserUseCase {
    private let repositoy: UserRepository
    
    init(repositoy: UserRepository) {
        self.repositoy = repositoy
    }
    
    func excute() async throws -> UserInfo? {
        try await repositoy.fetchUser().toEntity()
    }
}
