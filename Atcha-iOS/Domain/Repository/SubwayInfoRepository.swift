//
//  SubwayInfoRepository.swift
//  Atcha-iOS
//
//  Created by wodnd on 2/11/26.
//

import Foundation
protocol SubwayInfoRepository {
    // 실시간 지하철 정보 조회
    func subwayRealTimeInfo(_ request: SubwayRealTimeInfoRequest) async throws -> [SubwayRealTimeInfoResponse]
}
