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
    private let launchType: LaunchType
    
    var routerHandler: ((SplashRouter) -> Void)?
    
    init(navigationController: UINavigationController, diContainer: SplashDIContainer, launchType: LaunchType) {
        self.navigationController = navigationController
        self.diContainer = diContainer
        self.launchType = launchType
    }

    func start() {
        let viewModel = diContainer.makeSplashViewModel(launchType: launchType)
        let viewController = diContainer.makeSplashViewController(viewModel: viewModel)
        viewModel.routerHandler = { [weak self] router in
            self?.routerHandler?(router)
        }
        navigationController.pushViewController(viewController, animated: false)
    }
}
