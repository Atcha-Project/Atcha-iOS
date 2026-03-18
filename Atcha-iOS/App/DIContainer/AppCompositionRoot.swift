//
//  AppCompositionRoot.swift
//  Atcha-iOS
//
//  Created by Assistant on 2/20/26.
//

import UIKit
import Foundation

/// AppCompositionRoot is the single place where the application's dependency graph is built.
/// It replaces ad-hoc global/service-locator access by composing and owning all feature DI containers
/// and wiring Presentation/Domain/Data via constructor injection.
final class AppCompositionRoot {
    // MARK: Core dependencies
    let tokenStorage: TokenStorage
    let networkDIContainer: NetworkDIContainer
    let apiService: APIService
    let noHeaderApiService: APIService
    let locationStateHolder: LocationStateHolder
    
    // MARK: Feature DI containers
    let splashDIContainer: SplashDIContainer
    let loginDIContainer: LoginDIContainer
    let onboardingDIContainer: OnboardingDIContainer
    let mainDIContainer: MainDIContainer
    let lockScreenDIContainer: LockScreenDIContainer
    let introDIContainer: IntroDIContainer
    
    // MARK: - Init
    init() {
        // Core
        self.tokenStorage = TokenStorageImpl()
        self.networkDIContainer = NetworkDIContainer(tokenStorage: tokenStorage)
        self.apiService = networkDIContainer.makeAPIService()
        self.noHeaderApiService = networkDIContainer.makeAPIService(useInterceptor: false)
        self.locationStateHolder = LocationStateHolder()
        
        // Features
        self.splashDIContainer = SplashDIContainer(apiService: apiService,
                                                   tokenStorage: tokenStorage)
        self.loginDIContainer = LoginDIContainer(apiService: apiService, tokenStorage: tokenStorage)
        self.onboardingDIContainer = OnboardingDIContainer(apiService: apiService,
                                                           locationStateHolder: locationStateHolder)
        self.mainDIContainer = MainDIContainer(apiService: apiService,
                                               locationStateHolder: locationStateHolder,
                                               tokenStorage: tokenStorage)
        self.lockScreenDIContainer = LockScreenDIContainer(apiService: apiService)
        self.introDIContainer = IntroDIContainer()
    }
}

// MARK: - Coordinator factories forwarding
extension AppCompositionRoot: SplashCoordinatorFactory,
                              LoginCoordinatorFactory,
                              OnboardingCoordinatorFactory,
                              MainCoordinatorFactory,
                              LockScreenCoordinatorFactory,
                              IntroCoordinatorFactory {
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
    
    func makeIntroCoordinator(navigationController: UINavigationController) -> IntroCoordinator {
        return introDIContainer.makeIntroCoordinator(navigationController: navigationController)
    }
}
