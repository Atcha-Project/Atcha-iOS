//
//  SignOutUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/18/25.
//

import Foundation

protocol SignOutUseCase {
    func excute() async throws -> APIEmptyResponse
}

final class SignOutUseCaseImpl: SignOutUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func excute() async throws -> APIEmptyResponse {
        return try await repository.signOut()
    }
}
