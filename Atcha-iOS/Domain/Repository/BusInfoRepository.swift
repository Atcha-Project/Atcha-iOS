//
//  BusInfoRepository.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation

protocol BusInfoRepository {
    // 실시간 버스 정보 조회
    func busRealTimeInfo(_ request: BusRealTimeInfoRequest) async throws -> BusRealTimeInfoResponse
    
    // 실시간 버스 정보 조회 v2
    func getBusRealTimeInfo(_ request: String) async throws -> [RealTimeBusArrival]
    
    // 실시간 버스 정보 조회
    func busOperationInfo(_ request: BusOperationInfoRequest) async throws -> BusOperationInfoResponse
    
    // 버스 위치 정보 조회
    func busPositionInfo(_ request: BusPositionInfoRequest) async throws -> BusPositionInfoResponse
}
