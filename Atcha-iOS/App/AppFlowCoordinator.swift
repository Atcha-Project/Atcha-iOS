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
    
    init(window: UIWindow, container: AppDIContainer) {
        self.window = window
        self.container = container
    }
    
    func startApp() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        let splashCoordinator = container.makeSplashCoordinator(navigationController: navigationController)
        splashCoordinator.start()
        self.splashCoordinator = splashCoordinator
    }
}
