//
//  PushAlarmViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation
import Combine

enum PushAlarmContext {
    case myPage
}

final class PushAlarmViewModel: BaseViewModel {
    @Published private(set) var context: PushAlarmContext
    private let signUpUseCase: SignUpUseCase
    private let pushAlarmPatchUseCase: PushAlarmPatchUseCase
    private let locationStateHolder: LocationStateHolder
    
    var onFinish: ((Bool) -> Void)?
    var routeHandler: ((HomeRouter) -> Void)?
    
    init(context: PushAlarmContext,
         signUpUseCase: SignUpUseCase,
         pushAlarmPatchUseCase: PushAlarmPatchUseCase,
         locationStateHolder: LocationStateHolder) {
        self.context = context
        self.signUpUseCase = signUpUseCase
        self.pushAlarmPatchUseCase = pushAlarmPatchUseCase
        self.locationStateHolder = locationStateHolder
    }
}
