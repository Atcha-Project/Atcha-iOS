//
//  LogoutuseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import Foundation

protocol LogoutuseCase {
    func excute() async throws -> APIEmptyResponse
}

final class LogoutuseCaseCaseImpl: LogoutuseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func excute() async throws -> APIEmptyResponse {
        return try await repository.logout()
    }
}
