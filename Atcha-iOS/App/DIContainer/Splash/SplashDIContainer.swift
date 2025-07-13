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

    func makeCheckAppVersionUseCase() -> CheckAppVersionUseCase {
        let repository = AppVersionRepositoryImpl(apiService: apiService)
        return CheckAppVersionUseCaseImpl(repository: repository)
    }

    func makeSplashViewModel() -> SplashViewModel {
        SplashViewModel(checkAppVersionUseCase: makeCheckAppVersionUseCase())
    }
    
    func makeSplashViewController(viewModel: SplashViewModel) -> SplashViewController {
        return SplashViewController(viewModel: viewModel)
    }

    func makeSplashCoordinator(navigationController: UINavigationController) -> SplashCoordinator {
        SplashCoordinator(navigationController: navigationController,
                          diContainer: self)
    }
}
