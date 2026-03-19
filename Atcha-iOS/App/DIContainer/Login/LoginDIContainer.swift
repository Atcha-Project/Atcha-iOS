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
    private let tokenStorage: TokenStorage
    
    init(apiService: APIService, tokenStorage: TokenStorage) {
        self.apiService = apiService
        self.tokenStorage = tokenStorage
    }
    
    func makeLoginUseCase() -> LoginUseCase {
        let repository: UserRepository = UserRepositoryImpl(apiService: apiService, tokenStorage: tokenStorage)
        return LoginUseCaseImpl(repository: repository)
    }
    
    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(
            loginUseCase: makeLoginUseCase(),
            tokenStorage: tokenStorage 
        )
    }
    
    func makeLoginCoordinator(navigationController: UINavigationController) -> LoginCoordinator {
        LoginCoordinator(navigationController: navigationController,
                         diContainer: self)
    }
}
