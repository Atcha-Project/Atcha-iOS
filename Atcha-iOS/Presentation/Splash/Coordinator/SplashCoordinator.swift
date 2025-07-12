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
    
    var routerHandler: ((SplashRouter) -> Void)?
    
    init(navigationController: UINavigationController, diContainer: SplashDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }

    func start() {
        let viewModel = diContainer.makeSplashViewModel()
        let viewController = diContainer.makeSplashViewController(viewModel: viewModel)
        viewModel.routerHandler = { [weak self] router in
            self?.routerHandler?(router)
        }
        navigationController.pushViewController(viewController, animated: false)
    }
}
