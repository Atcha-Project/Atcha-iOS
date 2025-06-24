//
//  PushAlarmViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import Foundation

final class PushAlarmViewModel: BaseViewModel {
    private let onboardingUseCase: OnboardingUseCase
    
    init(onboardingUseCase: OnboardingUseCase) {
        self.onboardingUseCase = onboardingUseCase
    }
}
