//
//  AlarmRepository.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/8/25.
//

import Foundation

protocol AlarmRepository {
    // 알림 등록
    func alarmRegister(_ request: AlarmRequest) async throws -> APIEmptyResponse

    // 알림 취소
    func alarmDelete(_ request: AlarmRequest) async throws -> APIEmptyResponse
    
    // 출발시간 갱신
    func alarmRefresh(_ request: AlarmRequest) async throws -> AlarmRefreshResponse
}
