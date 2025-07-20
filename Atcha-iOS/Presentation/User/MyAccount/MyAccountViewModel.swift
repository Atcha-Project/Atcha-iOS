//
//  MyAccountViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/18/25.
//

import Foundation

final class MyAccountViewModel: BaseViewModel {
    var signOutFinish: (() -> Void)?
    
    private let signOutUseCase: SignOutUseCase
    private let logoutUseCase: LogoutuseCase

    init(signOutUseCase: SignOutUseCase,
         logoutUseCase: LogoutuseCase) {
        self.signOutUseCase = signOutUseCase
        self.logoutUseCase = logoutUseCase
    }
    
    func signOutTapped() {
        Task {
            do {
                let _ = try await signOutUseCase.excute()
                AppDIContainer.shared.tokenStorage.clearAllTokens()
                UserDefaultsWrapper().removeAll()
                signOutFinish?()
            } catch {
                print("error 발생")
            }
        }
    }
    
    func logoutTapped() {
        Task {
            do {
                let _ = try await logoutUseCase.excute()
                AppDIContainer.shared.tokenStorage.clearAccessToken()
                AppDIContainer.shared.tokenStorage.clearRefreshToken()
                UserDefaultsWrapper().remove(forKey: UserDefaultsWrapper.Key.providerToken.rawValue)
                UserDefaultsWrapper().remove(forKey: UserDefaultsWrapper.Key.provider.rawValue)
                signOutFinish?()
            } catch {
                print("error 발생")
            }
        }
    }
}
