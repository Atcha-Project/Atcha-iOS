//
//  OnboardingCoordinator.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import UIKit
import Foundation

final class OnboardingCoordinator {
    private let navigationController: UINavigationController
    private let diContainer: OnboardingDIContainer
    
    var onFinish: (() -> Void)?
    
    init(navigationController: UINavigationController, disContainer: OnboardingDIContainer, onFinish: (() -> Void)? = nil) {
        self.navigationController = navigationController
        self.diContainer = disContainer
    }
    
    func start() {
        let homeRegisterVC = HomeRegisterViewController(viewModel: diContainer.makeHomeRegisterViewModel())
        navigationController.pushViewController(homeRegisterVC, animated: true)
    }
    
    private func showPushAlarm() {
        let viewModel = diContainer.makePushAlarmViewModel()
        let pushAlarmVC = PushAlarmViewController(viewModel: viewModel)
        navigationController.pushViewController(pushAlarmVC, animated: true)
    }
    
}
