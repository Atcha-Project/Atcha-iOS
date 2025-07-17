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
    private let diContainer: MainDIContainer
    
    var routeHandler: ((MainRoute) -> Void)?
    
    init(navigationController: UINavigationController,
         diContainer: MainDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start() {
        let viewModel = diContainer.makeMainiewModel()
        viewModel.routeHandler = { [weak self] route in
            guard let self else { return }
            handle(route: route)
        }
        let viewController = diContainer.makeMainViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: false)
    }
    
    private func handle(route: MainRoute) {
        switch route {
        case .myPage:
            let vc = MyPageViewController(viewModel: MyPageViewModel())
            navigationController.pushViewController(vc, animated: true)
            print("✅ Pushed MapViewController: \(navigationController.viewControllers)")
        case let .courseSearch(startLat, startLon, startAddress):
            let vc = diContainer.makeCourseSearchViewController(startLat: startLat, startLon: startLon, startAddress: startAddress)
            navigationController.pushViewController(vc, animated: true)
            print("🔍 courseSearch route tapped: \(navigationController.viewControllers)")
        case .changeCourse:
            let vc = diContainer.makeCourseModifyViewController()
            navigationController.pushViewController(vc, animated: true)
            print("✍️ courseModify route tapped: \(navigationController.viewControllers)")
        }
        
        routeHandler?(route)
    }
}
