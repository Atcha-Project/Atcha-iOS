//
//  MyAccountDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/18/25.
//

import Foundation

final class MyAccountDIContainer {
    private let apiService: APIService
    private lazy var repository: UserRepository = UserRepositoryImpl(apiService: apiService)
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func makeMyAccountViewModel() -> MyAccountViewModel {
        
        let logoutUseCase: LogoutuseCase = LogoutuseCaseCaseImpl(repository: repository)
        return MyAccountViewModel(logoutUseCase: logoutUseCase)
    }
    
    func makeMyAccountViewController(viewModel: MyAccountViewModel) -> MyAccountViewController {
        return MyAccountViewController(viewModel: viewModel)
    }
    
    func makeWithdrawViewModel() -> WithdrawViewModel {
        let useCase: SignOutUseCase = SignOutUseCaseImpl(repository: repository)
        return WithdrawViewModel(signOutUseCase: useCase)
    }
    
    func makeWithdrawViewController(viewModel: WithdrawViewModel) -> WithdrawViewController {
        return WithdrawViewController(viewModel: viewModel)
    }
}
