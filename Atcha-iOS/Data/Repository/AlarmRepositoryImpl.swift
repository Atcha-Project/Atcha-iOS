//
//  AlarmRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/8/25.
//

import Foundation
import Alamofire

final class AlarmRepositoryImpl: AlarmRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func alarmRegister(_ request: AlarmRequest) async throws -> APIEmptyResponse {
        return try await apiService.request(
            Endpoint(
                path: "\(NetworkConstant.baseURL)/routes/user-routes",
                method: .post,
                encoding: JSONEncoding.default),
            body: request)
    }
    
    func alarmDelete(_ request: AlarmRequest) async throws -> APIEmptyResponse {
        return try await apiService.request(
            Endpoint(
                path: "\(NetworkConstant.baseURL)/routes/user-routes",
                method: .delete,
                parameters: [
                    "lastRouteId": request.lastRouteId
                ])
        )
    }
    
    func alarmRefresh() async throws -> AlarmRefreshResponse {
        return try await apiService.request(
            Endpoint(
                path: "\(NetworkConstant.baseURL)/routes/user-routes/refresh",
                method: .get)
        )
    }
}
