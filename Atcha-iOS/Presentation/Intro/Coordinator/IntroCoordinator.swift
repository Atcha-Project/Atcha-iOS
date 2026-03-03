//
//  LoginCoordinator.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/23/25.
//

import UIKit
import Foundation

final class IntroCoordinator {
    private let navigationController: UINavigationController
    private let diContainer: IntroDIContainer
    
    var onFinishWithGuest: (() -> Void)?
    
    init(navigationController: UINavigationController,
         diContainer: IntroDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start() {
        let viewModel = diContainer.makeIntroViewModel()

        viewModel.onFinishWithGuest = { [weak self] in
            self?.onFinishWithGuest?()
        }
        
        let viewController = IntroViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
