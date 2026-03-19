//
//  WithdrawViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/5/25.
//

import Foundation

final class WithdrawViewModel: BaseViewModel {
    var signOutFinish: (() -> Void)?
    private let tokenStorage: TokenStorage
    private let locationStateHolder: LocationStateHolder
    private let signOutUseCase: SignOutUseCase
    
    init(signOutUseCase: SignOutUseCase,
         tokenStorage: TokenStorage,
         locationStateHolder: LocationStateHolder) {
        self.signOutUseCase = signOutUseCase
        self.tokenStorage = tokenStorage
        self.locationStateHolder = locationStateHolder
    }
    
    func signOutTapped(_ request: WithdrawRequest) {
        Task {
            do {
                let _ = try await signOutUseCase.excute(request)
                let reason = request.reason?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                AmplitudeManager.shared.track(
                    .withdraw,
                    [AmplitudePropertyKey.withdrawReason.rawValue: reason ?? "unknown"]
                )
                AmplitudeManager.shared.reset()
                
                tokenStorage.clearAllTokens()
                UserDefaultsWrapper.shared.removeAll()
                locationStateHolder.clear()
                UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.hasSeenIntro.rawValue)
                signOutFinish?()
            } catch {
                print("error 발생")
            }
        }
    }
}
