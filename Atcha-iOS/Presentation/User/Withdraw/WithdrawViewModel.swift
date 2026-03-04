//
//  WithdrawViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/5/25.
//

import Foundation

final class WithdrawViewModel: BaseViewModel {
    var signOutFinish: (() -> Void)?
    
    private let signOutUseCase: SignOutUseCase
    init(signOutUseCase: SignOutUseCase) {
        self.signOutUseCase = signOutUseCase
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
                
                AppDIContainer.shared.tokenStorage.clearAllTokens()
                UserDefaultsWrapper.shared.removeAll()
                AppDIContainer.shared.locationStateHolder.clear()
                UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.hasSeenIntro.rawValue)
                signOutFinish?()
            } catch {
                print("error 발생")
            }
        }
    }
}
