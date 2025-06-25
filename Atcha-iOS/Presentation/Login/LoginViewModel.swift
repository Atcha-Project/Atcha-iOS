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
    
    var onLoginSuccess: (() -> Void)?
    
    func kakaoLoginTapped() {
        Task {
            do {
                let token = try await loginUseCase.signUpWithKakao()
                print("카카오 로그인 성공. token: \(token)")
                login(token: token, type: .kakao)
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
                delegateHolder(delegate)
                print("애플 로그인 성공. token: \(token)")
                login(token: token, type: .apple)
            } catch {
                print("애플 로그인 실패: \(error.localizedDescription)")
                delegateHolder(nil) // 실패 시 해제
            }
        }
    }
}

// MARK: - Login
extension LoginViewModel {
    private func login(token: String,
                       type: LoginType) {
        let request: LoginRequest = LoginRequest(accessToken: token,
                                                 provider: type.rawValue)
        Task {
            let _ = try? await loginUseCase.login(request)
            // TODO: - 서버 통신 정상적으로 되면 로직 변경
            onLoginSuccess?()
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
