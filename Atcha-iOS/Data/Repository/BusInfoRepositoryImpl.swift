//
//  BusInfoRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/30/25.
//

import Foundation
import Alamofire

final class BusInfoRepositoryImpl: BusInfoRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    // 실시간 버스 정보 조회
    func busRealTimeInfo(_ request: BusRealTimeInfoRequest) async throws -> BusRealTimeInfoResponse {
        return try await apiService.request(
            Endpoint(
                path: "/transits/bus-arrival",
                method: .post,
                encoding: JSONEncoding.default
            ),
            body: request)
    }
    
    // 실시간 버스 정보 조회 - v2
    func getBusRealTimeInfo(_ request: String) async throws -> [RealTimeBusArrival] {
        return try await apiService.request(
            Endpoint(
                path: "/routes/user-routes/bus-arrival",
                method: .get,
                parameters: ["routeName" : request]
            )
        )
    }
    
    // 실시간 버스 정보 조회
    func busOperationInfo(_ request: BusOperationInfoRequest) async throws -> BusOperationInfoResponse {
        return try await apiService.request(
            Endpoint(
                path: "/transits/bus-routes/operation-info",
                method: .get,
                parameters: [
                    "busRouteId": request.busRouteId ?? "",
                    "routeName": request.routeName ?? "",
                    "serviceRegion": request.serviceRegion ?? ""
                ]
            )
        )
    }
    
    // 버스 위치 정보 조회
    func busPositionInfo(_ request: BusPositionInfoRequest) async throws -> BusPositionInfoResponse {
        return try await apiService.request(
            Endpoint(
                path: "/transits/bus-routes/positions",
                method: .get,
                parameters: [
                    "busRouteId": request.busRouteId ?? "",
                    "routeName": request.routeName ?? "",
                    "serviceRegion": request.serviceRegion ?? ""
                ]
            )
        )
    }
}
