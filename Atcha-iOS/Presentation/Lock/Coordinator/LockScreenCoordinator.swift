//
//  LockScreenCoordinator.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 8/4/25.
//

import UIKit
import Foundation

final class LockScreenCoordinator {
    private let navigationController: UINavigationController
    private let diContainer: LockScreenDIContainer
    
    var routerHandler: ((MainRoute) -> Void)?
    
    init(navigationController: UINavigationController, diContainer: LockScreenDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }

    func start() {
        let viewModel = diContainer.makeLockScreenViewModel()
        let viewController = diContainer.makeLockScreenViewController(viewModel: viewModel)
        viewModel.routerHandler = { [weak self] router in
            self?.routerHandler?(router)
        }
        navigationController.pushViewController(viewController, animated: false)
    }
}
