//
//  MainCoordinator.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/22/25.
//

import UIKit
import TMapSDK
import Foundation

final class MainCoordinator {
    private let navigationController: UINavigationController
    private let diContainer: LocationDIContainer

    init(navigationController: UINavigationController,
         diContainer: LocationDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }

    func start() {
//        let mainCoordinator = diContainer.makeMainCoordinator(navigationController: navigationController)
//        mainCoordinator.diContainer.makeMapViewController()
        let viewController = diContainer.makeMapViewController()
        navigationController.pushViewController(viewController, animated: false)
    }
}
