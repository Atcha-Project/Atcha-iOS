//
//  LoginRepository.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/22/25.
//

import Foundation

protocol LoginRepository {
    func checkRegistration(_ request: AuthCheckRequest) async throws -> AuthCheckResponse
    func login(_ request: LoginRequest) async throws -> LoginResponse
//    func logout() async throws
//    func signUp(_ request: SignUpRequest) async throws
//    func withdraw() async throws
}
