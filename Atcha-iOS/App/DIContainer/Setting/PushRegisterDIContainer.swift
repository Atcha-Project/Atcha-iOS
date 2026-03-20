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
    private let tokenStorage: TokenStorage
    
    init(apiService: APIService,
         locationStateHolder: LocationStateHolder,
         tokenStorage: TokenStorage) {
        self.apiService = apiService
        self.locationStateHolder = locationStateHolder
        self.tokenStorage = tokenStorage
    }
    
    func makePushRegisterViewModel(context: PushAlarmContext) -> PushAlarmViewModel {
        let userRepository = UserRepositoryImpl(apiService: apiService, tokenStorage: tokenStorage)
        
        let signUpUseCase: SignUpUseCase = SignUpUseCaseImpl(repository: userRepository)
        let pushAlarmPatchUseCase: PushAlarmPatchUseCase = PushAlarmPatchUseCaseImpl(repository: userRepository)
        
        return PushAlarmViewModel(context: context,
                                  signUpUseCase: signUpUseCase,
                                  pushAlarmPatchUseCase: pushAlarmPatchUseCase,
                                  locationStateHolder: locationStateHolder)
    }
    
    func makePushRegisterViewController(viewModel: PushAlarmViewModel) -> PushAlarmViewController {
        return PushAlarmViewController(viewModel: viewModel)
    }
}
