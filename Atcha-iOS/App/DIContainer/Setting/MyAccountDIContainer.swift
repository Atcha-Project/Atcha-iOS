//
//  MyAccountDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/18/25.
//

import Foundation

final class MyAccountDIContainer {
    private let apiService: APIService
    private let tokenStorage: TokenStorage
    private let locationStateHolder: LocationStateHolder
    
    private lazy var repository: UserRepository = UserRepositoryImpl(apiService: apiService)
    
    init(apiService: APIService,
         tokenStorage: TokenStorage,
         locationStateHolder: LocationStateHolder) {
        self.apiService = apiService
        self.tokenStorage = tokenStorage
        self.locationStateHolder = locationStateHolder
    }
    
    func makeMyAccountViewModel() -> MyAccountViewModel {
        let logoutUseCase: LogoutuseCase = LogoutuseCaseCaseImpl(repository: repository)
        
        return MyAccountViewModel(
            logoutUseCase: logoutUseCase,
            tokenStorage: tokenStorage,
            locationStateHolder: locationStateHolder
        )
    }
    
    func makeMyAccountViewController(viewModel: MyAccountViewModel) -> MyAccountViewController {
        return MyAccountViewController(viewModel: viewModel)
    }
    
    func makeWithdrawViewModel() -> WithdrawViewModel {
        let useCase: SignOutUseCase = SignOutUseCaseImpl(repository: repository)
        return WithdrawViewModel(signOutUseCase: useCase, tokenStorage: tokenStorage, locationStateHolder: locationStateHolder)
    }
    
    func makeWithdrawViewController(viewModel: WithdrawViewModel) -> WithdrawViewController {
        return WithdrawViewController(viewModel: viewModel)
    }
}
