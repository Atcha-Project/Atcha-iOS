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
        guard let token = AppDIContainer.shared.tokenStorage.accessToken else {
            throw NSError(domain: "BusInfoRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "인증 토큰이 없습니다."])
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/transits/bus-arrival",
                method: .post,
                parameters: [
                    "routeName": request.routeName,
                    "stationName": request.stationName,
                    "lat": request.lat,
                    "lon": request.lon,
                    "passStations": request.passStations
                ],
                headers: headers
            )
        )
    }
    
    // 실시간 버스 정보 조회
    func busOperationInfo(_ request: BusOperationInfoRequest) async throws -> BusOperationInfoResponse {
        guard let token = AppDIContainer.shared.tokenStorage.accessToken else {
            throw NSError(domain: "BusInfoRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "인증 토큰이 없습니다."])
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/transits/bus-routes/operation-info",
                method: .get,
                parameters: [
                    "busRouteId": request.busRouteId,
                    "routeName": request.routeName,
                    "serviceRegion": request.serviceRegion
                ],
                headers: headers
            )
        )
    }
    
    // 버스 위치 정보 조회
    func busPositionInfo(_ request: BusPositionInfoRequest) async throws -> BusPositionInfoResponse {
        guard let token = AppDIContainer.shared.tokenStorage.accessToken else {
            throw NSError(domain: "BusInfoRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "인증 토큰이 없습니다."])
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/transits/bus-routes/positions",
                method: .get,
                parameters: [
                    "busRouteId": request.busRouteId,
                    "routeName": request.routeName,
                    "serviceRegion": request.serviceRegion
                ],
                headers: headers
            )
        )
    }
}
