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

    var routeHandler: ((MainRoute) -> Void)?

    init(navigationController: UINavigationController,
         diContainer: LocationDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }

    func start() {
        let viewModel = diContainer.makeLocationViewModel()
        viewModel.routeHandler = { [weak self] route in
            guard let self else { return }
            handle(route: route)
        }
        let viewController = MapViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: false)
    }
    
    private func handle(route: MainRoute) {
        switch route {
        case .myPage:
            let vc = MyPageViewController(viewModel: MyPageViewModel())
            navigationController.pushViewController(vc, animated: true)
            print("✅ Pushed MapViewController: \(navigationController.viewControllers)")
        case .courseSearch:
            print("🔍 courseSearch route tapped")

        case .changeCourse:
            print("🔄 changeCourse route tapped")
        }

        routeHandler?(route)
    }
}
