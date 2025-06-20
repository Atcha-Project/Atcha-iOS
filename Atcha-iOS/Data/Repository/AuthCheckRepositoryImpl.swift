//
//  AuthCheckRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import Foundation

final class AuthCheckRepositoryImpl: AuthCheckRepository {
    
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func checkMemberRegistration(_ request: AuthCheckRequest) async throws -> AuthCheckResponse {
        
        return try await apiService.request(
            Endpoint(
                path: "http://atcha.p-e.kr/api/auth/check",
                method: .get,
                parameters: ["provider": "\(request.provider)"],
                headers: ["Authorization": "Bearer \(request.accessToken)"]
            )
        )
    }
    
}
