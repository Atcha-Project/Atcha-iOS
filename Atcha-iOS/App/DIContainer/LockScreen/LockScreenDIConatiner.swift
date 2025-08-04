//
//  LockScreenDIConatiner.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 8/4/25.
//

import UIKit

final class LockScreenDIContainer {
    func makeLockScreenViewModel() -> LockViewModel {
        return LockViewModel(taxiFare: 30000)
    }
    
    func makeLockScreenViewController(viewModel: LockViewModel) -> LockViewController {
        return LockViewController(viewModel: viewModel)
    }
    
    func makeLockScreenCoordinator(navigationController: UINavigationController) -> LockScreenCoordinator {
        return LockScreenCoordinator(navigationController: navigationController,
                                     diContainer: self)
    }
}
