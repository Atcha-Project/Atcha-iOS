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
    func makeSplashCoordinator(navigationController: UINavigationController, launchType: LaunchType) -> SplashCoordinator
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

protocol IntroCoordinatorFactory {
    func makeIntroCoordinator(navigationController: UINavigationController) -> IntroCoordinator
}

/// A convenience alias that groups all coordinator factory protocols used to bootstrap flows.
typealias AppCoordinatorFactory = SplashCoordinatorFactory & LoginCoordinatorFactory & OnboardingCoordinatorFactory & MainCoordinatorFactory & LockScreenCoordinatorFactory & IntroCoordinatorFactory

extension AppDIContainer: SplashCoordinatorFactory,
                          LoginCoordinatorFactory,
                          OnboardingCoordinatorFactory,
                          MainCoordinatorFactory,
                          LockScreenCoordinatorFactory,
                          IntroCoordinatorFactory {
    func makeSplashCoordinator(navigationController: UINavigationController, launchType: LaunchType) -> SplashCoordinator {
        return splashDIContainer.makeSplashCoordinator(navigationController: navigationController, launchType: launchType)
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
    
    func makeIntroCoordinator(navigationController: UINavigationController) -> IntroCoordinator {
        return introDIContainer.makeIntroCoordinator(navigationController: navigationController)
    }
}

