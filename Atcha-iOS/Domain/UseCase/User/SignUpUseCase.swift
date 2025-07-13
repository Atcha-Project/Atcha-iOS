//
//  SignUpUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/12/25.
//

import Foundation

protocol SignUpUseCase {
    func excute(_ request: SignUpRequest) async throws -> SignUpResponse
}

final class SignUpUseCaseImpl: SignUpUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func excute(_ request: SignUpRequest) async throws -> SignUpResponse {
        return try await repository.signUp(request)
    }
}
