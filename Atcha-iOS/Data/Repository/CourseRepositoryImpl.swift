//
//  CourseRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/7/25.
//

import Foundation
import Alamofire

final class CourseRepositoryImpl: CourseRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func courseSearch(_ request: CourseSearchRequest) async throws -> [CourseSearchResponse] {
        
        guard let token = AppDIContainer.shared.tokenStorage.accessToken else {
            throw NSError(domain: "CourseRepository", code: 401, userInfo: [NSLocalizedDescriptionKey: "인증 토큰이 없습니다."])
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)"
        ]
        
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/transits/last-routes",
                method: .get,
                parameters: [
                    "startLat": request.startLat,
                    "startLon": request.startLon,
                    "endLat": request.endLat,
                    "endLon": request.endLon,
                    "sortType": request.sortType
                ],
                headers: headers,
            ))
    }
}
