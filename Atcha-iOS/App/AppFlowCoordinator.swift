//
//  AppFlowCoordinator.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import UIKit
import Foundation

class AppFlowCoordinator {
    private let container: AppDIContainer
    private let window: UIWindow
    
    private var splashCoordinator: SplashCoordinator?
    private var mainCoordinator: MainCoordinator?
    
    init(window: UIWindow, container: AppDIContainer) {
        self.window = window
        self.container = container
    }
    
    func startApp() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        let splashCoordinator = container.makeSplashCoordinator(navigationController: navigationController)
        splashCoordinator.onFinish = { [weak self] in
            guard let self else { return }
            showMainFlow()
        }
        splashCoordinator.start()
        self.splashCoordinator = splashCoordinator
    }
    
    private func showMainFlow() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
//        mainCoordinator = MainCoordinator(navigationController: navigationController,
//                                          diContainer: container)
//        mainCoordinator?.start()
        
        let viewModel = HomeRegisterViewModel()
        let homeRegisterVC = HomeRegisterViewController(viewModel: viewModel)
        navigationController.pushViewController(homeRegisterVC, animated: false)
    }
}
