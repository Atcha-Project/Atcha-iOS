//
//  AppDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import UIKit
import Foundation

final class AppDIContainer {
    private let compositionRoot: AppCompositionRoot
    @available(*, deprecated, message: "Use AppCompositionRoot and pass it from SceneDelegate instead.")
    static let shared = AppDIContainer()
    
    var tokenStorage: TokenStorage
    let networkDIContainer: NetworkDIContainer
    
    let splashDIContainer: SplashDIContainer
    let loginDIContainer: LoginDIContainer
    let mainDIContainer: MainDIContainer
    let onboardingDIContainer: OnboardingDIContainer
    let lockScreenDIContainer: LockScreenDIContainer
    let introDIContainer: IntroDIContainer
    
    let locationStateHolder: LocationStateHolder
    
    private init() {
        // Forward to a single composition root to unify dependency creation
        self.compositionRoot = AppCompositionRoot()

        // Core
        self.tokenStorage = compositionRoot.tokenStorage
        self.networkDIContainer = compositionRoot.networkDIContainer

        // Features
        self.splashDIContainer = compositionRoot.splashDIContainer
        self.loginDIContainer = compositionRoot.loginDIContainer
        self.onboardingDIContainer = compositionRoot.onboardingDIContainer
        self.mainDIContainer = compositionRoot.mainDIContainer
        self.lockScreenDIContainer = compositionRoot.lockScreenDIContainer
        self.introDIContainer = compositionRoot.introDIContainer
        
        // Shared state holders
        self.locationStateHolder = compositionRoot.locationStateHolder
    }
}

