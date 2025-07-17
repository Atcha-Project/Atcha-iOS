//
//  PermissionDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/16/25.
//

import Foundation
import PanModal

final class PermissionDIContainer {
    private let authorizationRequestUseCase = RequestLocationAuthorizationUseCaseImpl(repository: PermissionRepositoryImpl())
    private let streamUseCase = ObserLocationStreamUseCaseImpl(repository: LocationStreamRepositoryImpl())
    private let locationStateHolder: LocationStateHolder
    
    init(locationStateHolder: LocationStateHolder) {
        self.locationStateHolder = locationStateHolder
    }
    
    func makePermissionViewModel() -> PermissionViewModel {
        return PermissionViewModel(authorizationRequestUseCase: authorizationRequestUseCase,
                                   streamUseCase: streamUseCase,
                                   locationStateHolder: locationStateHolder)
    }
    
    func makePermissionViewController(viewModel: PermissionViewModel) -> PermissionViewController {
        return PermissionViewController(viewModel: viewModel)
    }
}
