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

    // 나머지 로그인/회원가입/로그아웃 등도 여기에 구현
}
