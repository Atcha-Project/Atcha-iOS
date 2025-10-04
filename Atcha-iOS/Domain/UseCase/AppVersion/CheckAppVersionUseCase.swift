//
//  CheckAppVersionUseCase.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation

protocol CheckAppVersionUseCase {
    func execute() async throws -> String
}

final class CheckAppVersionUseCaseImpl: CheckAppVersionUseCase {
    private let repository: AppVersionRepository
    
    init(repository: AppVersionRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> String {
        return try await repository.fetchAppVersion()
    }
}
