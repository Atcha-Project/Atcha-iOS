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
    private var myPageCoordinator: MyPageCoordinator?
    private var courseModifyCoordinator: CourseModifyCoordinator?
    
    var signoutFinish: (() -> Void)?
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
            let myPageDI = diContainer.makeMyPageDIContainer()
            let myPageCoordinator = MyPageCoordinator(
                navigationController: navigationController,
                diContainer: myPageDI
            )
            self.myPageCoordinator = myPageCoordinator
            myPageCoordinator.signoutFinish = self.signoutFinish 
            myPageCoordinator.start()
        case let .courseSearch(startLat, startLon, startAddress):
            let courseDI = diContainer.makeCourseDIContainer()
            let vc = courseDI.makeCourseSearchViewController(startLat: startLat, startLon: startLon, startAddress: startAddress)
            navigationController.pushViewController(vc, animated: true)
            print("🔍 courseSearch route tapped: \(navigationController.viewControllers)")
        case .changeCourse:
            let courseDI = diContainer.makeCourseDIContainer()
            let courseModifyCoordinator = CourseModifyCoordinator(
                navigationController: navigationController,
                diContainer: courseDI)
            self.courseModifyCoordinator = courseModifyCoordinator
            courseModifyCoordinator.start()
        }
        
        routeHandler?(route)
    }
}
