//
//  UserInfoPatchUseCase.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/5/25.
//

import Foundation

protocol HomePatchUseCase {
    func homePatch(_ request: HomePatchRequest) async throws -> UserInfoPatchResponse
}

final class HomePatchUseCaseImpl: HomePatchUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func homePatch(_ request: HomePatchRequest) async throws -> UserInfoPatchResponse {
        return try await repository.homePatch(request)
    }
}
