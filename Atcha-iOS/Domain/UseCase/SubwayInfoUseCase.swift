//
//  SubwayInfoUseCase.swift
//  Atcha-iOS
//
//  Created by wodnd on 2/11/26.
//

import Foundation

protocol SubwayInfoUseCase {
    // 실시간 지하철 정보 조회
    func subwayRealTimeInfo(_ request: SubwayRealTimeInfoRequest) async throws -> [SubwayRealTimeInfo]
}

final class SubwayInfoUseCaseImpl: SubwayInfoUseCase {
    private let repository: SubwayInfoRepository
    
    init(repository: SubwayInfoRepository) {
        self.repository = repository
    }
    
    // 실시간 버스 정보 조회
    func subwayRealTimeInfo(_ request: SubwayRealTimeInfoRequest) async throws -> [SubwayRealTimeInfo] {
        let dtos = try await repository.subwayRealTimeInfo(request)
        return dtos.compactMap { $0.toEntity() }
    }
}
