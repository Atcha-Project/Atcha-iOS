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
    private let diContainer: AppDIContainer
    
    init(navigationController: UINavigationController, diContainer: AppDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start() {
        let viewModel = diContainer.splashDIContainer.makeSplashViewModel()
        let viewController = SplashViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: false)
    }
}
