//
//  LoginViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import Foundation
import AuthenticationServices

final class LoginViewModel: BaseViewModel {
    private let loginUseCase: LoginUseCase
    
    init(loginUseCase: LoginUseCase) {
        self.loginUseCase = loginUseCase
    }
    
    func kakaoLoginTapped() {
        Task {
            do {
                let token = try await loginUseCase.signUpWithKakao()
                print("카카오 로그인 성공. token: \(token)")
                checkRegistration(provider: 0, token: token)
            } catch {
                print("카카오 로그인 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func appleLoginTapped(
        presentationContextProvider: ASAuthorizationControllerPresentationContextProviding,
        delegateHolder: @escaping (AppleLoginDelegateWrapper?) -> Void
    ) {
        Task {
            do {
                let (token, delegate) = try await loginUseCase.signUpWithApple(presentationContextProvider: presentationContextProvider)
                
                // ✅ 반드시 ViewController 에 먼저 delegate 저장!
                delegateHolder(delegate)

                print("애플 로그인 성공. token: \(token)")
                checkRegistration(provider: 1, token: token)

                // ⭐️ 해제는 ViewController 의 화면 전환(completion) 시점에서 해주는게 더 안전

            } catch {
                print("애플 로그인 실패: \(error.localizedDescription)")
                delegateHolder(nil) // 실패 시 해제
            }
        }
    }
    
    func checkRegistration(provider: Int, token: String) {
        Task {
            let request = AuthCheckRequest(provider: provider, accessToken: token)
            let result = try await loginUseCase.checkRegistration(request)
            
            switch result {
            case .registered:
                print("회원 → 로그인 진행")
            case .notRegistered:
                print("비회원 → 회원가입 유도")
            default:
                break
            }
        }
    }
}
