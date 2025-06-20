//
//  CheckMemberRegisteredUseCase.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import Foundation

protocol CheckMemberRegisteredUseCase {
    func execute(_ request: AuthCheckRequest) async throws -> AuthCheckResponse
}

final class CheckMemberRegisteredUseCaseImpl: CheckMemberRegisteredUseCase {
    
    private let repository: AuthCheckRepository
    
    init(repository: AuthCheckRepository) {
        self.repository = repository
    }
    
    func execute(_ request: AuthCheckRequest) async throws -> AuthCheckResponse {
        return try await repository.checkMemberRegistration(request)
    }
}
