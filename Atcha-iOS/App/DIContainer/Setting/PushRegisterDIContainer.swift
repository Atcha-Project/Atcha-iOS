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
    
    func makePushRegisterViewModel(context: PushAlarmContext) -> PushAlarmViewModel {
        let signUpUseCase: SignUpUseCase = SignUpUseCaseImpl(repository: UserRepositoryImpl(apiService: apiService))
        let pushAlarmPatchUseCase: PushAlarmPatchUseCase = PushAlarmPatchUseCaseImpl(repository: UserRepositoryImpl(apiService: apiService))
        return PushAlarmViewModel(context: context,
                                  signUpUseCase: signUpUseCase,
                                  pushAlarmPatchUseCase: pushAlarmPatchUseCase,
                                  locationStateHolder: locationStateHolder)
    }
    
    func makePushRegisterViewController(viewModel: PushAlarmViewModel) -> PushAlarmViewController {
        return PushAlarmViewController(viewModel: viewModel)
    }
}
