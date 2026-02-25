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
    
    var onFinishWithExistUser: ((Bool) -> Void)?
    var onFinishWithGuest: (() -> Void)?
    
    init(navigationController: UINavigationController,
         diContainer: LoginDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start() {
        let viewModel = diContainer.makeLoginViewModel()
        viewModel.isExistUser = { [weak self] isExist in
            self?.onFinishWithExistUser?(isExist)
        }
        
        viewModel.onFinishWithGuest = { [weak self] in
            self?.onFinishWithGuest?()
        }
        
        let viewController = LoginViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
