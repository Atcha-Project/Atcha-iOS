//
//  DIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

final class DIContainer {
    lazy var apiClient: APIClient = {
        APIClient()
    }()
    
    lazy var userRepository: UserRepository = {
        UserRepositoryImpl(apiClient: apiClient)
    }()
    
    lazy var userUseCase: UserUseCase = {
        UserUseCase(repositoy: userRepository)
    }()
    
    func makeSplashViewModel() -> SplashViewModel {
        return SplashViewModel(useCase: userUseCase)
    }
}
