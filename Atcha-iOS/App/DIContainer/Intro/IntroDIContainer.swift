//
//  LoginDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/23/25.
//

import UIKit
import Foundation

final class IntroDIContainer {
    func makeIntroViewModel() -> IntroViewModel {
        IntroViewModel()
    }
    
    func makeIntroCoordinator(navigationController: UINavigationController) -> IntroCoordinator {
        IntroCoordinator(navigationController: navigationController,
                         diContainer: self)
    }
}
