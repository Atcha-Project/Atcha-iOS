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
    
    var isExistUser: ((Bool) -> Void)?
    
    func kakaoLoginTapped() {
        Task {
            do {
                let token = try await loginUseCase.signUpWithKakao()
                print("카카오 로그인 성공. token: \(token)")
                checkRegistration(provider: .kakao, token: token)
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
                checkRegistration(provider: .apple, token: token)
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
                       type: LoginType) async {
        let request: LoginRequest = LoginRequest(accessToken: token,
                                                 provider: type.rawValue)
        Task {
            do {
                let response = try await loginUseCase.login(request)
                
                AppDIContainer.shared.tokenStorage.accessToken = response.accessToken
                AppDIContainer.shared.tokenStorage.refreshToken = response.refreshToken
                
                if let lat = response.latitude,
                   let lon = response.longitude {
                    UserDefaultsWrapper().set(lat, forKey: UserDefaultsWrapper.Key.homeLat.rawValue)
                    UserDefaultsWrapper().set(lon, forKey: UserDefaultsWrapper.Key.homeLon.rawValue)
                }
                
                print("로그인 완료")
            } catch {
                print("로그인 실패: \(error.localizedDescription)")
            }
        }
    }
    
    func checkRegistration(provider: LoginType, token: String) {
        Task {
            let request = AuthCheckRequest(provider: provider.rawValue, accessToken: token)
            let result = try await loginUseCase.checkRegistration(request)
            
            UserDefaultsWrapper().set(token, forKey: UserDefaultsWrapper.Key.providerToken.rawValue)
            UserDefaultsWrapper().set(provider.rawValue, forKey: UserDefaultsWrapper.Key.provider.rawValue)
            
            switch result {
            case .registered:
                await login(token: token, type: provider)
                isExistUser?(true)
                print("회원 → 로그인 진행")
            case .notRegistered:
                isExistUser?(false)
                print("비회원 → 회원가입 유도")
            default:
                break
            }
        }
    }
}
