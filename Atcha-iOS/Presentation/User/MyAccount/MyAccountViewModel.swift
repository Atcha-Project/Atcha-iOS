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
    private let tokenStorage: TokenStorage
    private let locationStateHolder: LocationStateHolder
    
    init(logoutUseCase: LogoutuseCase,
         tokenStorage: TokenStorage,
         locationStateHolder: LocationStateHolder) {
        self.logoutUseCase = logoutUseCase
        self.tokenStorage = tokenStorage
        self.locationStateHolder = locationStateHolder
    }
    
    func logoutTapped() {
        Task {
            do {
                let _ = try await logoutUseCase.excute()
                
                let userId = UserDefaultsWrapper.shared.integer(forKey: UserDefaultsWrapper.Key.userId.rawValue) ?? 0
                DiscordWebhookManager.shared.sendAuthLog(
                    event: .logout,
                    userID: String(userId)
                )
                
                AmplitudeManager.shared.track(.logout)
                AmplitudeManager.shared.reset()
                
                tokenStorage.clearAllTokens()
                UserDefaultsWrapper.shared.removeAll()
                locationStateHolder.clear()
                
                UserDefaults.standard.set(true, forKey: "IsAppFirstLaunchedEver")
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
