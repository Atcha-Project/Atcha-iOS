//
//  SplashCoordinator.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/21/25.
//

import UIKit
import Foundation

final class SplashCoordinator {
    private let navigationController: UINavigationController
    private let diContainer: SplashDIContainer
    
    var onFinish: (() -> Void)?
    
    init(navigationController: UINavigationController, diContainer: SplashDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }

    func start() {
        let viewModel = diContainer.makeSplashViewModel()
        let viewController = SplashViewController(viewModel: viewModel)
        viewModel.onSignUpCompleted = { [weak self] in
            guard let self else { return }
            onFinish?()
        }
        navigationController.pushViewController(viewController, animated: false)
    }
}
