//
//  SubwayInfoRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by wodnd on 2/11/26.
//

import Foundation
import Alamofire

final class SubwayInfoRepositoryImpl: SubwayInfoRepository {
    
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    // 실시간 지하철 정보 조회
    func subwayRealTimeInfo(_ request: SubwayRealTimeInfoRequest) async throws -> [SubwayRealTimeInfoResponse] {
        let res: APIResponse<[SubwayRealTimeInfoResponse]> = try await apiService.request(
            Endpoint(
                path: "/routes/user-routes/subway-arrival",
                method: .post,
                encoding: JSONEncoding.default
            ),
            body: request
        )
        return res.result ?? []
    }
}
