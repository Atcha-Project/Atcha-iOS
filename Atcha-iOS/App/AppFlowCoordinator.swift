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
    private var loginCoordinator: LoginCoordinator?
    
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
            // 로그인 됐으면 mainFlow 아니면 LoginFlow
//            showMainFlow()
            showLoginFlow()
        }
        splashCoordinator.start()
        self.splashCoordinator = splashCoordinator
    }
    
    private func showMainFlow() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        mainCoordinator = MainCoordinator(navigationController: navigationController,
                                          diContainer: container)
        mainCoordinator?.start()
    }
    
    private func showLoginFlow() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let loginCoordinator = container.makeLoginCoordinator(navigationController: navigationController)
        loginCoordinator.onFinishWithExistUser = { [weak self] isExist in
            DispatchQueue.main.async {
                isExist ? self?.showMainFlow() : self?.showOnboardingFlow()
            }
        }
        loginCoordinator.start()
        self.loginCoordinator = loginCoordinator
        
//        let viewModel = RegisterLocationViewModel()
//        let homeRegisterVC = RegisterLocationViewController(viewModel: viewModel)
//        navigationController.pushViewController(homeRegisterVC, animated: false)
    }
    
    private func showOnboardingFlow() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let onboardingCoordinator = container.makeOnboardingCoordinator(navigationController: navigationController)
        onboardingCoordinator.start()
    }
}
