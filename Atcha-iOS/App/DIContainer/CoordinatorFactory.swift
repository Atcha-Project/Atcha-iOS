//
//  CoordinatorFactory.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/22/25.
//

import UIKit
import Foundation

/// CoordinatorFactory protocols define how feature coordinators are constructed.
/// These protocols are conformed to by the application's composition root (see `AppCompositionRoot`)
/// to avoid service locator style lookups and to enable constructor injection of dependencies.

protocol SplashCoordinatorFactory {
    func makeSplashCoordinator(navigationController: UINavigationController) -> SplashCoordinator
}

protocol LoginCoordinatorFactory {
    func makeLoginCoordinator(navigationController: UINavigationController) -> LoginCoordinator
}

protocol OnboardingCoordinatorFactory {
    func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator
}

protocol MainCoordinatorFactory {
    func makeMainCoordinator(navigationController: UINavigationController) -> MainCoordinator
}

protocol LockScreenCoordinatorFactory {
    func makeLockScreenCoordinator(navigationController: UINavigationController) -> LockScreenCoordinator
}

/// A convenience alias that groups all coordinator factory protocols used to bootstrap flows.
typealias AppCoordinatorFactory = SplashCoordinatorFactory & LoginCoordinatorFactory & OnboardingCoordinatorFactory & MainCoordinatorFactory & LockScreenCoordinatorFactory

extension AppDIContainer: SplashCoordinatorFactory,
                          LoginCoordinatorFactory,
                          OnboardingCoordinatorFactory,
                          MainCoordinatorFactory,
                          LockScreenCoordinatorFactory {
    func makeSplashCoordinator(navigationController: UINavigationController) -> SplashCoordinator {
        return splashDIContainer.makeSplashCoordinator(navigationController: navigationController)
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
    
    func makeLockScreenCoordinator(navigationController: UINavigationController) -> LockScreenCoordinator {
        return lockScreenDIContainer.makeLockScreenCoordinator(navigationController: navigationController)
    }
}

