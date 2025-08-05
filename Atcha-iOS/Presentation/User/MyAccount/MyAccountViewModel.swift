//
//  MyAccountViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/18/25.
//

import Foundation

final class MyAccountViewModel: BaseViewModel {
    var logout: (() -> Void)?
    var signOutFinish: (() -> Void)?
    
    private let logoutUseCase: LogoutuseCase
    
    init(logoutUseCase: LogoutuseCase) {
        self.logoutUseCase = logoutUseCase
    }
    
    func logoutTapped() {
        Task {
            do {
                let _ = try await logoutUseCase.excute()
                AppDIContainer.shared.tokenStorage.clearAccessToken()
                AppDIContainer.shared.tokenStorage.clearRefreshToken()
                //                UserDefaultsWrapper().remove(forKey: UserDefaultsWrapper.Key.providerToken.rawValue)
                //                UserDefaultsWrapper().remove(forKey: UserDefaultsWrapper.Key.provider.rawValue)
                UserDefaultsWrapper().removeAll()
                await MainActor.run {
                    logout?()
                }
            } catch {
                print("error 발생")
            }
        }
    }
}
