//
//  AlarmUseCase.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/8/25.
//

import Foundation

protocol AlarmUseCase {
    // 알림 등록
    func alarmRegister(_ request: AlarmRequest) async throws -> APIEmptyResponse
    
    // 알림 취소
    func alarmDelete(_ request: AlarmRequest) async throws -> APIEmptyResponse
    
    // 출발시간 갱신
    func alarmRefresh() async throws -> AlarmRefresh
}

final class AlarmUseCaseImpl: AlarmUseCase {
    private let repository: AlarmRepository
    
    init(repository: AlarmRepository) {
        self.repository = repository
    }
    
    // 알림 등록
    func alarmRegister(_ request: AlarmRequest) async throws -> APIEmptyResponse {
        return try await repository.alarmRegister(request)
    }
    
    // 알림 취소
    func alarmDelete(_ request: AlarmRequest) async throws -> APIEmptyResponse {
        return try await repository.alarmDelete(request)
    }
    
    // 출발시간 갱신
    func alarmRefresh() async throws -> AlarmRefresh {
        guard let entity = try await repository.alarmRefresh().toEntity() else {
            throw NSError(domain: "AlarmUseCaseError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "AlarmRefresh 변환 실패"
            ])
        }
        return entity
    }
}
