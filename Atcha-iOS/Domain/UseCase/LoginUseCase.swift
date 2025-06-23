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
import AuthenticationServices

protocol LoginUseCase {
    func checkRegistration(_ request: AuthCheckRequest) async throws -> LoginResult
    
    @MainActor func signUpWithKakao() async throws -> String
    @MainActor func signUpWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) async throws -> (String, AppleLoginDelegateWrapper)
//    func login(_ request: LoginRequest) async throws -> LoginResult
//    func logout() async throws -> LoginResult
//    func signUp(_ request: SignUpRequest) async throws -> LoginResult
//    func withdraw() async throws -> LoginResult
}

final class LoginUseCaseImpl: LoginUseCase {
    private var delegate: AppleLoginDelegateWrapper? = nil
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
    
    @MainActor
    func signUpWithApple(presentationContextProvider: ASAuthorizationControllerPresentationContextProviding) async throws -> (String, AppleLoginDelegateWrapper) {
        return try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])

            delegate = AppleLoginDelegateWrapper { result in
                switch result {
                case .success(let credential):
                    if let tokenData = credential.identityToken,
                       let token = String(data: tokenData, encoding: .utf8) {
                        continuation.resume(returning: (token, self.delegate!))
                    } else {
                        continuation.resume(throwing: NSError(domain: "AppleLogin", code: -1, userInfo: nil))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            controller.delegate = delegate
            controller.presentationContextProvider = presentationContextProvider
            controller.performRequests()
        }
    }
}
