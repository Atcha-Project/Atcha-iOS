//
//  AppFlowCoordinator.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import UIKit

class AppFlowCoordinator {
    private let container: DIContainer
    private let window: UIWindow
    
    init(window: UIWindow, container: DIContainer) {
        self.window = window
        self.container = container
    }
    
    func startApp() {
        let viewModel = container.makeSplashViewModel()
        let viewController = SplashViewController(viewModel: viewModel)
        
        let navigationController = UINavigationController(rootViewController: viewController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
