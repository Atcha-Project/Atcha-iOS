//
//  SplashDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/21/25.
//

import UIKit
import Foundation

final class SplashDIContainer {
    private let apiService: APIService
    private let tokenStorage: TokenStorage
    
    init(apiService: APIService, tokenStorage: TokenStorage) {
        self.apiService = apiService
        self.tokenStorage = tokenStorage
    }
    
    func makeFetchUserUseCase() -> FetchUserUseCase {
        let repository: UserRepository = UserRepositoryImpl(apiService: apiService, tokenStorage: tokenStorage)
        return FetchUserUseCaseImpl(repositoy: repository)
    }
    
    func makeCheckAppVersionUseCase() -> CheckAppVersionUseCase {
        let repository = AppVersionRepositoryImpl(apiService: apiService)
        return CheckAppVersionUseCaseImpl(repository: repository)
    }
    
    func makeUpdateAppVersionUseCase() -> UpdateAppVersionUseCase {
        let repository = AppVersionRepositoryImpl(apiService: apiService)
        return UpdateAppVersionUseCaseImpl(repository: repository)
    }
    
    func makeSplashViewModel() -> SplashViewModel {
        return SplashViewModel(
            fetchUserUseCase: makeFetchUserUseCase(),
            checkAppVersionUseCase: makeCheckAppVersionUseCase(),
            updateAppVersionUseCase: makeUpdateAppVersionUseCase(),
            tokenStorage: tokenStorage
        )
    }
    
    func makeSplashViewController(viewModel: SplashViewModel) -> SplashViewController {
        return SplashViewController(viewModel: viewModel)
    }
    
    func makeSplashCoordinator(navigationController: UINavigationController) -> SplashCoordinator {
        SplashCoordinator(navigationController: navigationController,
                          diContainer: self)
    }
}
