//
//  DIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import Foundation

final class AppDIContainer {
    static let shared = AppDIContainer()
    
    private let tokenStorage: TokenStorage
    let networkDIContainer: NetworkDIContainer
    
    private init() {
        self.tokenStorage = TokenStorageImpl()
        self.networkDIContainer = NetworkDIContainer(tokenStorage: tokenStorage)
    }
}

final class DIContainer {
    lazy var apiService: APIService = {
        AppDIContainer.shared.networkDIContainer.makeAPIService()
    }()
    
    lazy var userRepository: UserRepository = {
        UserRepositoryImpl(apiService: apiService)
    }()
    
    lazy var userUseCase: FetchUserUseCase = {
        FetchUserUseCaseImpl(repositoy: userRepository)
    }()
    
    lazy var appVersionRepository: AppVersionRepository = {
        AppVersionRepositoryImpl(apiService: apiService)
    }()
    
    lazy var appVersionUseCase: CheckAppVersionUseCase = {
        CheckAppVersionUseCaseImpl(repository: appVersionRepository)
    }()
    
    func makeSplashViewModel() -> SplashViewModel {
        return SplashViewModel(checkAppVersionUseCase: appVersionUseCase)
    }
}
