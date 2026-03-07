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
                AmplitudeManager.shared.track(.logout)
                AmplitudeManager.shared.reset()
                
                AppDIContainer.shared.tokenStorage.clearAccessToken()
                AppDIContainer.shared.tokenStorage.clearRefreshToken()
                UserDefaultsWrapper.shared.removeAll()
                AppDIContainer.shared.locationStateHolder.clear()
                UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.isGuest.rawValue)
                UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.hasSeenIntro.rawValue)
                await MainActor.run {
                    logout?()
                }
            } catch {
                print("error 발생")
            }
        }
    }
}
