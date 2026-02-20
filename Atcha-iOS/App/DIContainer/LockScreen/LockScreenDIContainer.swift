//
//  LockScreenDIConatiner.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 8/4/25.
//

import UIKit

final class LockScreenDIContainer {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    private lazy var fetchTaxiFareUseCase = FetchTaxiFareUseCaseImpl(repository: FetchTaxiFareRepositoryImpl(apiService: apiService))
    
    func makeLockScreenViewModel() -> LockViewModel {
        return LockViewModel(taxiFare: 0,
                             fetchTaxiFareUseCase: fetchTaxiFareUseCase)
    }
    
    func makeLockScreenViewController(viewModel: LockViewModel) -> LockViewController {
        return LockViewController(viewModel: viewModel)
    }
    
    func makeLockScreenCoordinator(navigationController: UINavigationController) -> LockScreenCoordinator {
        return LockScreenCoordinator(navigationController: navigationController,
                                     diContainer: self)
    }
}
