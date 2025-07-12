//
//  PushRegisterDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/12/25.
//

import Foundation

final class PushRegisterDIContainer {
    private let apiService: APIService
    private let locationStateHolder: LocationStateHolder
    
    init(apiService: APIService,
         locationStateHolder: LocationStateHolder) {
        self.apiService = apiService
        self.locationStateHolder = locationStateHolder
    }
    
    func makePushRegisterViewModel() -> PushAlarmViewModel {
        let useCase: SignUpUseCase = SignUpUseCaseImpl(repository: UserRepositoryImpl(apiService: apiService))
        return PushAlarmViewModel(signUpUseCase: useCase)
    }
    
    func makePushRegisterViewController() -> PushAlarmViewController {
        return PushAlarmViewController(viewModel: makePushRegisterViewModel())
    }
}
