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
            routeHandler?(route)
//            switch route {
//            case .myPage:
//                print("마이 페이지 이동")
//            case .courseSearch:
//                print("검색 이동")
//            case .changeCourse:
//                print("경로 변경이동")
//            }
        }
        let viewController = MapViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: false)
    }
}
