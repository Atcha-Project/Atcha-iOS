//
//  LoginViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/21/25.
//

import Foundation


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
                checkRegistration(provider: 1, token: token)
            } catch {
                print("카카오 로그인 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func appleLoginTapped() {
        
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
