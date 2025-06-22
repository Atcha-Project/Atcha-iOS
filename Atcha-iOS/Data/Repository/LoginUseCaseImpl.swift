//
//  LoginUseCaseImpl.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/22/25.
//

import Foundation

final class LoginUseCaseImpl: LoginUseCase {
    
    private let repository: LoginRepository
    
    init(repository: LoginRepository) {
        self.repository = repository
    }
    
    func checkRegistration(_ request: AuthCheckRequest) async throws -> LoginResult {
        let result = try await repository.checkRegistration(request)
        return result.exists ? .registered(result) : .notRegistered
    }
    
//    func login(_ request: LoginRequest) async throws -> LoginResult {
//    
//    }
//    
//    func logout() async throws -> LoginResult {
//        
//    }
//    
//    func signUp(_ request: SignUpRequest) async throws -> LoginResult {
//
//    }
//    
//    func withdraw() async throws -> LoginResult {
//
//    }
}
