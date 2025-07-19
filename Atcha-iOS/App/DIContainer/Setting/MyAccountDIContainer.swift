//
//  MyAccountDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/18/25.
//

import Foundation

final class MyAccountDIContainer {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func makeMyAccountViewModel() -> MyAccountViewModel {
        let repository: UserRepository = UserRepositoryImpl(apiService: apiService)
        let useCase: SignOutUseCase = SignOutUseCaseImpl(repository: repository)
        let logoutUseCase: LogoutuseCase = LogoutuseCaseCaseImpl(repository: repository)
        return MyAccountViewModel(signOutUseCase: useCase, logoutUseCase: logoutUseCase)
    }
    
    func makeMyAccountViewController(viewModel: MyAccountViewModel) -> MyAccountViewController {
        return MyAccountViewController(viewModel: viewModel)
    }
}
