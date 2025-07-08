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

protocol LoginCoordinatorFactory {
    func makeLoginCoordinator(navigationController: UINavigationController) -> LoginCoordinator
}

protocol OnboardingCoordinatorFactory {
    func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator
}

protocol MainCoordinatorFactory {
    func makeMainCoordinator(navigationController: UINavigationController) ->
    MainCoordinator
}

extension AppDIContainer: SplashCoordinatorFactory, MyPageCoordinatorFactory, MainCoordinatorFactory {
    
    func makeSplashCoordinator(navigationController: UINavigationController) -> SplashCoordinator {
        return splashDIContainer.makeSplashCoordinator(navigationController: navigationController)
    }

    func makeMyPageCoordinator(navigationController: UINavigationController) -> MyPageCoordinator {
        return myPageDIContainer.makeMyPageCoordinator(navigationController: navigationController)
    }
    
    func makeLoginCoordinator(navigationController: UINavigationController) -> LoginCoordinator {
        return loginDIContainer.makeLoginCoordinator(navigationController: navigationController)
    }
    
    func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator {
        return onboardingDIContainer.makeOnboardingCoordinator(navigationController: navigationController)
    }
    
    func makeMainCoordinator(navigationController: UINavigationController) -> MainCoordinator {
        return mainDIContainer.makeMainCoordinator(navigationController: navigationController)
    }
    
    func makeCourseCoordinator(navigationController: UINavigationController) -> CourseCoordinator {
        return courseDIContainer.makeCourseCoordinator(navigationController: navigationController)
    }
}
