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
        let endpoint = Endpoint(
            path: "/routes/user-routes/subway-arrival",
            method: .get,
            parameters: ["routeName": request.routeName],
            encoding: URLEncoding.queryString,
            headers: ["Authorization": "Bearer \(AppDIContainer.shared.tokenStorage.accessToken ?? "")"],
        )
        
        let result: [SubwayRealTimeInfoResponse] = try await apiService.request(endpoint)
        return result
    }
}

