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
    
    var showMyPage: (() -> Void)?

    init(navigationController: UINavigationController,
         diContainer: LocationDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }

    func start() {
        let viewModel = diContainer.makeLocationViewModel()
        viewModel.goMyPage = { [weak self] in
            guard let self else { return }
            showMyPage?()
        }
        let viewController = MapViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: false)
    }
}
