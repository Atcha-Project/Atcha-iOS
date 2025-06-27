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
    
    var onFinish: ((Bool) -> Void)?
    
    init(navigationController: UINavigationController, disContainer: OnboardingDIContainer, onFinish: ((Bool) -> Void)? = nil) {
        self.navigationController = navigationController
        self.diContainer = disContainer
        self.onFinish = onFinish
    }
    
    func start() {
        let viewModel = diContainer.makeHomeRegisterViewModel()
        viewModel.onFinish = { [weak self] success in
            self?.onFinish?(success)
        }
        
        let homeRegisterVC = HomeRegisterViewController(viewModel: viewModel)
        homeRegisterVC.onNextTapped = { [weak self] location in
            guard let self else {
                print("❌ OnboardingCoordinator 가 이미 deinit 되어 사라짐")
                return
            }
            self.showPushAlarm(with: location)
            print("✅ showPushAlarm 호출 시도함, location =", location)
        }
        navigationController.pushViewController(homeRegisterVC, animated: true)
    }
    
    private func showPushAlarm(with location: SelectedLocation) {
        let viewModel = diContainer.makePushAlarmViewModel()
        viewModel.selectedLocation = location
        
        viewModel.onFinish = { [weak self] success in
            self?.onFinish?(success)
        }
        
        let pushAlarmVC = PushAlarmViewController(viewModel: viewModel)
        navigationController.pushViewController(pushAlarmVC, animated: true)
    }
}
