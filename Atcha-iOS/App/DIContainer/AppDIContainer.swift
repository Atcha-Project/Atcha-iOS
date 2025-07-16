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
    let homeRegisterDIContainer: HomeRegisterDIContainer
    let pushRegisterDIContainer: PushRegisterDIContainer
    let permissionDIConatiner: PermissionDIContainer
    
    private let locationStateHolder: LocationStateHolder = LocationStateHolder()
    
    private init() {
        self.tokenStorage = TokenStorageImpl()
        self.networkDIContainer = NetworkDIContainer(tokenStorage: tokenStorage)
        
        let apiServce: APIService = networkDIContainer.makeAPIService()
        let noHeaderApiService: APIService = networkDIContainer.makeAPIService(useInterceptor: false)
      
        self.splashDIContainer = SplashDIContainer(apiService: apiServce)
        self.myPageDIContainer = MyPageDIContainer(apiService: apiServce)
        self.loginDIContainer = LoginDIContainer(apiService: noHeaderApiService)
        self.mainDIContainer = LocationDIContainer(apiService: apiServce, locationStateHolder: locationStateHolder)
        
        self.homeRegisterDIContainer = HomeRegisterDIContainer(apiService: apiServce, locationStateHolder: locationStateHolder)
        self.pushRegisterDIContainer = PushRegisterDIContainer(apiService: apiServce, locationStateHolder: locationStateHolder)
        self.permissionDIConatiner = PermissionDIContainer(locationStateHolder: locationStateHolder)
        
        self.onboardingDIContainer = OnboardingDIContainer(apiService: apiServce,
                                                           locationStateHolder: locationStateHolder,
                                                           homeRegisterDIConatiner: homeRegisterDIContainer,
                                                           pushRegisterDIContainer: pushRegisterDIContainer,
                                                           permissionDIContainer: permissionDIConatiner)
    }
}
