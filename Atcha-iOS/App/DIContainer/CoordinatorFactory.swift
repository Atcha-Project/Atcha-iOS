//
//  CoordinatorFactory.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/22/25.
//

import UIKit
import Foundation

protocol SplashCoordinatorFactory {
    func makeSplashCoordinator(navigationController: UINavigationController) -> SplashCoordinator
}

protocol MyPageCoordinatorFactory {
    func makeMyPageCoordinator(navigationController: UINavigationController) -> MyPageCoordinator
}

extension AppDIContainer: SplashCoordinatorFactory, MyPageCoordinatorFactory {
    func makeSplashCoordinator(navigationController: UINavigationController) -> SplashCoordinator {
        return splashDIContainer.makeSplashCoordinator(navigationController: navigationController)
    }

    func makeMyPageCoordinator(navigationController: UINavigationController) -> MyPageCoordinator {
        return myPageDIContainer.makeMyPageCoordinator(navigationController: navigationController)
    }
}
