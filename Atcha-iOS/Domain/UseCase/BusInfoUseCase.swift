//
//  BusInfoUseCase.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation

protocol BusInfoUseCase {
    // 실시간 버스 정보 조회
    func busRealTimeInfo(_ request: BusRealTimeInfoRequest) async throws -> BusRealTimeInfo
    
    // 실시간 버스 정보 조회 v2
    func getBusRealTimeInfo(_ request: String) async throws -> [RealTimeBusArrival]
    
    // 버스 운행 정보 조회
    func busOperationInfo(_ request: BusOperationInfoRequest) async throws -> BusOperationInfo
    
    // 버스 위치 정보 조회
    func busPositionInfo(_ request: BusPositionInfoRequest) async throws -> BusPositionInfo
}

final class BusInfoUseCaseImpl: BusInfoUseCase {
    private let repository: BusInfoRepository
    
    init(repository: BusInfoRepository) {
        self.repository = repository
    }
    
    // 실시간 버스 정보 조회
    func busRealTimeInfo(_ request: BusRealTimeInfoRequest) async throws -> BusRealTimeInfo {
        guard let entity = try await repository.busRealTimeInfo(request).toEntity() else {
            throw NSError(domain: "BusInfoUseCaseError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "BusRealTimeInfo 변환 실패"
            ])
        }
        return entity
    }
    
    // 실시간 버스 정보 조회 v2
    func getBusRealTimeInfo(_ request: String) async throws -> [RealTimeBusArrival] {
        return try await repository.getBusRealTimeInfo(request)
    }
    
    // 버스 운행 정보 조회
    func busOperationInfo(_ request: BusOperationInfoRequest) async throws -> BusOperationInfo {
        guard let entity = try await repository.busOperationInfo(request).toEntity() else {
            throw NSError(domain: "BusInfoUseCaseError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "BusOperationInfo 변환 실패"
            ])
        }
        return entity
    }
    
    // 버스 위치 정보 조회
    func busPositionInfo(_ request: BusPositionInfoRequest) async throws -> BusPositionInfo {
        guard let entity = try await repository.busPositionInfo(request).toEntity() else {
            throw NSError(domain: "BusInfoUseCaseError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "BusPositionInfo 변환 실패"
            ])
        }
        return entity
    }
}
