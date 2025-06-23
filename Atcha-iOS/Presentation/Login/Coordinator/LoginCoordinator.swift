//
//  LoginCoordinator.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/23/25.
//

import UIKit
import Foundation

final class LoginCoordinator {
    private let navigationController: UINavigationController
    private let diContainer: LoginDIContainer
    
    var onFinish: (() -> Void)?
    
    init(navigationController: UINavigationController,
         diContainer: LoginDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start() {
        let viewModel = diContainer.makeLoginViewModel()
        let viewController = LoginViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
//    func start() {
//        let viewModel = diContainer.makeLoginCoordinator(navigationController: )
//    }
}
