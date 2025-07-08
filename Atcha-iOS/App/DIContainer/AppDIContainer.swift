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
    let mainDIContainer: LocationDIContainer
    let onboardingDIContainer: OnboardingDIContainer
    let courseDIContainer: CourseDIContainer

    private init() {
        self.tokenStorage = TokenStorageImpl()
        self.networkDIContainer = NetworkDIContainer(tokenStorage: tokenStorage)
        
        let apiServce: APIService = networkDIContainer.makeAPIService()
        let noHeaderApiService: APIService = networkDIContainer.makeAPIService(useInterceptor: false)
        let locationService: LocationServiceProtocol = LocationService()
        
        self.splashDIContainer = SplashDIContainer(apiService: apiServce)
        self.myPageDIContainer = MyPageDIContainer(apiService: apiServce)
        self.loginDIContainer = LoginDIContainer(apiService: noHeaderApiService)
        self.mainDIContainer = LocationDIContainer(apiService: apiServce)
        self.onboardingDIContainer = OnboardingDIContainer(apiService: apiServce, locationService: locationService)
        self.courseDIContainer = CourseDIContainer(apiService: apiServce)
    }
}
