//
//  PushAlarmSetting.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/6/25.
//

import Foundation

protocol PushAlarmPatchUseCase {
    func pushAlarmPatch(_ request: PushAlarmPatchRequest) async throws -> UserInfoPatchResponse
}

final class PushAlarmPatchUseCaseImpl: PushAlarmPatchUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func pushAlarmPatch(_ request: PushAlarmPatchRequest) async throws -> UserInfoPatchResponse {
        return try await repository.pushAlarmPatch(request)
    }
}
