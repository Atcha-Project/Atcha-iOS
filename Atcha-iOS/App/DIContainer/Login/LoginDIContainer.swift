//
//  LoginDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/23/25.
//

import UIKit
import Foundation

final class LoginDIContainer {
    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func makeLoginUseCase() -> LoginUseCase {
        let repository: UserRepository = UserRepositoryImpl(apiService: apiService)
        return LoginUseCaseImpl(repository: repository)
    }

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(loginUseCase: makeLoginUseCase())
    }
    
    func makeLoginCoordinator(navigationController: UINavigationController) -> LoginCoordinator {
        LoginCoordinator(navigationController: navigationController,
                         diContainer: self)
    }
}
