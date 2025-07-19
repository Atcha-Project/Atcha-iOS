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

    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func makeFetchUserUseCase() -> FetchUserUseCase {
        let repository: UserRepository = UserRepositoryImpl(apiService: apiService)
        return FetchUserUseCaseImpl(repositoy: repository)
    }

    func makeCheckAppVersionUseCase() -> CheckAppVersionUseCase {
        let repository = AppVersionRepositoryImpl(apiService: apiService)
        return CheckAppVersionUseCaseImpl(repository: repository)
    }

    func makeSplashViewModel() -> SplashViewModel {
        SplashViewModel(fetchUserUseCase: makeFetchUserUseCase(),
                        checkAppVersionUseCase: makeCheckAppVersionUseCase())
    }
    
    func makeSplashViewController(viewModel: SplashViewModel) -> SplashViewController {
        return SplashViewController(viewModel: viewModel)
    }

    func makeSplashCoordinator(navigationController: UINavigationController) -> SplashCoordinator {
        SplashCoordinator(navigationController: navigationController,
                          diContainer: self)
    }
}
