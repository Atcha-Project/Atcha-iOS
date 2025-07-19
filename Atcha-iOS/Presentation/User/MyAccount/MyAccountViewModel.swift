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

    init(signOutUseCase: SignOutUseCase) {
        self.signOutUseCase = signOutUseCase
    }
    
    func signOutTapped() {
        Task {
            do {
                let _ = try await signOutUseCase.excute()
                AppDIContainer.shared.tokenStorage.clearAllTokens()
                signOutFinish?()
            } catch {
                print("error 발생")
            }
        }
    }
}
