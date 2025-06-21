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
    let userDIContainer: UserDIContainer
    let splashDIContainer: SplashDIContainer

    private init() {
        self.tokenStorage = TokenStorageImpl()
        self.networkDIContainer = NetworkDIContainer(tokenStorage: tokenStorage)
        self.userDIContainer = UserDIContainer(apiService: networkDIContainer.makeAPIService())
        self.splashDIContainer = SplashDIContainer(apiService: networkDIContainer.makeAPIService())
    }
    
    func makeSplashCoordinator(navigationController: UINavigationController) -> SplashCoordinator {
        return SplashCoordinator(navigationController: navigationController, diContainer: self)
    }
}
