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

    private let tokenStorage: TokenStorage
    let networkDIContainer: NetworkDIContainer
    
    let myPageDIContainer: MyPageDIContainer
    let splashDIContainer: SplashDIContainer

    private init() {
        self.tokenStorage = TokenStorageImpl()
        self.networkDIContainer = NetworkDIContainer(tokenStorage: tokenStorage)
        
        self.splashDIContainer = SplashDIContainer(apiService: networkDIContainer.makeAPIService())
        self.myPageDIContainer = MyPageDIContainer(apiService: networkDIContainer.makeAPIService())
    }
}
