//
//  AppDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import UIKit
import Foundation

final class AppDIContainer {
    static let shared = AppDIContainer()
    
    var tokenStorage: TokenStorage
    let networkDIContainer: NetworkDIContainer
    
    let splashDIContainer: SplashDIContainer
    let loginDIContainer: LoginDIContainer
    let mainDIContainer: MainDIContainer
    let onboardingDIContainer: OnboardingDIContainer
    let lockScreenDIContainer: LockScreenDIContainer
    
    let locationStateHolder: LocationStateHolder = LocationStateHolder()
    
    private init() {
        self.tokenStorage = TokenStorageImpl()
        self.networkDIContainer = NetworkDIContainer(tokenStorage: tokenStorage)
        
        let apiServce: APIService = networkDIContainer.makeAPIService()
        let noHeaderApiService: APIService = networkDIContainer.makeAPIService(useInterceptor: false)
      
        self.splashDIContainer = SplashDIContainer(apiService: apiServce)
        self.loginDIContainer = LoginDIContainer(apiService: noHeaderApiService)
        self.onboardingDIContainer = OnboardingDIContainer(apiService: apiServce,
                                                           locationStateHolder: locationStateHolder)
        self.mainDIContainer = MainDIContainer(apiService: apiServce,
                                               locationStateHolder: locationStateHolder)
        self.lockScreenDIContainer = LockScreenDIContainer()
    }
}
