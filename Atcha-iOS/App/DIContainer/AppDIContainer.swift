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
    
    let myPageDIContainer: MyPageDIContainer
    let splashDIContainer: SplashDIContainer
    let loginDIContainer: LoginDIContainer
    let onboardingDIContainer: OnboardingDIContainer

    private init() {
        self.tokenStorage = TokenStorageImpl()
        self.networkDIContainer = NetworkDIContainer(tokenStorage: tokenStorage)
        
        let apiServce: APIService = networkDIContainer.makeAPIService()
        let locationService: LocationServiceProtocol = LocationService()
        
        self.splashDIContainer = SplashDIContainer(apiService: apiServce)
        self.myPageDIContainer = MyPageDIContainer(apiService: apiServce)
        self.loginDIContainer = LoginDIContainer(apiService: apiServce)
        self.onboardingDIContainer = OnboardingDIContainer(apiService: apiServce, locationService: locationService)
    }
}
