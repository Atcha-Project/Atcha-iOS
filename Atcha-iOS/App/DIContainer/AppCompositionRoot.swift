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

    // MARK: - Init
    init() {
        // Core
        self.tokenStorage = TokenStorageImpl()
        self.networkDIContainer = NetworkDIContainer(tokenStorage: tokenStorage)
        self.apiService = networkDIContainer.makeAPIService()
        self.noHeaderApiService = networkDIContainer.makeAPIService(useInterceptor: false)
        self.locationStateHolder = LocationStateHolder()

        // Features
        self.splashDIContainer = SplashDIContainer(apiService: apiService)
        self.loginDIContainer = LoginDIContainer(apiService: noHeaderApiService)
        self.onboardingDIContainer = OnboardingDIContainer(apiService: apiService,
                                                           locationStateHolder: locationStateHolder)
        self.mainDIContainer = MainDIContainer(apiService: apiService,
                                               locationStateHolder: locationStateHolder)
        self.lockScreenDIContainer = LockScreenDIContainer(apiService: apiService)
    }
}

// MARK: - Coordinator factories forwarding
extension AppCompositionRoot: SplashCoordinatorFactory,
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
