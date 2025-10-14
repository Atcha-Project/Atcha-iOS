//
//  UpdateAppVersionUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 10/4/25.
//

import Foundation

protocol UpdateAppVersionUseCase {
    func exectue(version: String) async throws -> APIEmptyResponse
}

final class UpdateAppVersionUseCaseImpl: UpdateAppVersionUseCase {
    private let repository: AppVersionRepository
    
    init(repository: AppVersionRepository) {
        self.repository = repository
    }
    
    func exectue(version: String) async throws -> APIEmptyResponse {
        return try await repository.updateAppVersion(version: AppVersionRequest(version: version))
    }
}
