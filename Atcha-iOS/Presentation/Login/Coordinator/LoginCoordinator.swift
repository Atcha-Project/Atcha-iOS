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
    var onCancel: (() -> Void)?
    
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
        
        viewModel.loginCancelled = { [weak self] in
            self?.onCancel?()
        }
        
        let viewController = LoginViewController(viewModel: viewModel)
        viewController.modalPresentationStyle = .overFullScreen
        navigationController.present(viewController, animated: false)
    }
}
