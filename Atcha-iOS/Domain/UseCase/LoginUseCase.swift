//
//  LoginUseCase.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/22/25.
//

import Foundation

// 로그인 시나리오 결과
enum LoginResult {
    case registered(AuthCheckResponse)
    case notRegistered
    case loginSuccess(TokenResponse)
    case loginFailed(Error)
    case logoutSuccess
    case signUpSuccess
    case withdrawalSuccess
}

// 유즈케이스
protocol LoginUseCase {
    func checkRegistration(_ request: AuthCheckRequest) async throws -> LoginResult
//    func login(_ request: LoginRequest) async throws -> LoginResult
//    func logout() async throws -> LoginResult
//    func signUp(_ request: SignUpRequest) async throws -> LoginResult
//    func withdraw() async throws -> LoginResult
}
