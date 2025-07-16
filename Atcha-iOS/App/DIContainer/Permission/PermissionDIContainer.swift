//
//  PermissionDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/16/25.
//

import Foundation
import PanModal

final class PermissionDIContainer {
    private lazy var authorizationRequestUseCase = RequestLocationAuthorizationUseCaseImpl(repository: PermissionRepositoryImpl())
    
    func makePermissionViewModel() -> PermissionViewModel {
        return PermissionViewModel(authorizationRequestUseCase: authorizationRequestUseCase)
    }
    
    func makePermissionViewController() -> PermissionViewController {
        return PermissionViewController(viewModel: makePermissionViewModel())
    }
}
