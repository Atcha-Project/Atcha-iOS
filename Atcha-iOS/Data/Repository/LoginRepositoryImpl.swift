//
//  LoginRepositoryImpl.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/22/25.
//

import Foundation
final class LoginRepositoryImpl: LoginRepository {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func checkRegistration(_ request: AuthCheckRequest) async throws -> AuthCheckResponse {
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/auth/check",
                method: .get,
                parameters: ["provider": "\(request.provider)"],
                headers: ["Authorization": "Bearer \(request.accessToken)"]
            )
        )
    }

    func login(_ request: LoginRequest) async throws -> LoginResponse {
        return try await apiService.request(
            Endpoint(
                path: "https://atcha.p-e.kr/api/auth/login",
                method: .get,
                parameters: [
                    "provider": "\(request.provider)",
                    "fcmToken": AppDIContainer.shared.tokenStorage.fcmToken ?? ""
                ],
                headers: ["Authorization": "Bearer \(request.accessToken)"]
            )
        )
    }
}
