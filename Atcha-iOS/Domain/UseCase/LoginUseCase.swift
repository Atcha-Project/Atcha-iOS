//
//  LoginUseCase.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/22/25.
//

import Foundation
import KakaoSDKAuth
import KakaoSDKCommon
import KakaoSDKUser

protocol LoginUseCase {
    func checkRegistration(_ request: AuthCheckRequest) async throws -> LoginResult
    
    @MainActor func signUpWithKakao() async throws -> String
    @MainActor  func singUpWithApple() async throws -> String
//    func login(_ request: LoginRequest) async throws -> LoginResult
//    func logout() async throws -> LoginResult
//    func signUp(_ request: SignUpRequest) async throws -> LoginResult
//    func withdraw() async throws -> LoginResult
}

final class LoginUseCaseImpl: LoginUseCase {
    private let repository: LoginRepository
    
    init(repository: LoginRepository) {
        self.repository = repository
    }
    
    func checkRegistration(_ request: AuthCheckRequest) async throws -> LoginResult {
        let result = try await repository.checkRegistration(request)
        return result.exists ? .registered(result) : .notRegistered
    }
    
    @MainActor
    func signUpWithKakao() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk { (oauthToken, error) in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let token = oauthToken?.accessToken {
                        continuation.resume(returning: token)
                    } else {
                        continuation.resume(throwing: NSError(domain: "KakaoLogin", code: -1, userInfo: nil))
                    }
                }
            } else {
                UserApi.shared.loginWithKakaoAccount { (oauthToken, error) in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let token = oauthToken?.accessToken {
                        continuation.resume(returning: token)
                    } else {
                        continuation.resume(throwing: NSError(domain: "KakaoLogin", code: -1, userInfo: nil))
                    }
                }
            }
        }
    }
    
    @MainActor func singUpWithApple() async throws -> String {
        return ""
    }
}
