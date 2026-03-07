//
//  IntroViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 3/3/26.
//

import Foundation
import AuthenticationServices

final class IntroViewModel: BaseViewModel {

    var onFinishWithGuest: (() -> Void)?
    
}

// MARK: - Intro
extension IntroViewModel {
    func guestLoginTapped() {
        UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.isGuest.rawValue)
        onFinishWithGuest?()
    }
}
