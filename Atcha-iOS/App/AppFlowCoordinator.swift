//
//  AppFlowCoordinator.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/19/25.
//

import UIKit
import Foundation

class AppFlowCoordinator {
    private let container: AppDIContainer
    private let window: UIWindow
    
    private var splashCoordinator: SplashCoordinator?
    private var mainCoordinator: MainCoordinator?
    private var loginCoordinator: LoginCoordinator?
    private var onboardingCoordinator: OnboardingCoordinator?
    private var lockScreenCoordinator: LockScreenCoordinator?
    
    init(window: UIWindow, container: AppDIContainer) {
        self.window = window
        self.container = container
    }
    
    func startApp() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        let splashCoordinator = container.makeSplashCoordinator(navigationController: navigationController)
        splashCoordinator.routerHandler = { [weak self] router in
            guard let self else { return }
            switch router {
            case .login:
                showLoginFlow()
            case .main:
                showMainFlow()
            case .onboarding:
                showOnboardingFlow()
            case .alarm(let info, let address):
                showMainFlow(info: info, address: address, bottomType: .departure)
            case .lockScreen(let info, let address):
                showLockScreenFlow(info: info, address: address)
            case .detailRoute(let lat, let lon, let address):
                print("lat : \(lat), lon : \(lon), address : \(address)")
            }
        }
        splashCoordinator.start()
        self.splashCoordinator = splashCoordinator
    }
    
    private func showMainFlow(info: LegInfo? = nil,
                              address: String? = nil,
                              bottomType: MapBottomType = .search) {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        mainCoordinator = container.makeMainCoordinator(navigationController: navigationController)
        mainCoordinator?.signoutFinish = { [weak self] in
            DispatchQueue.main.async {
                self?.showLoginFlow()
            }
        }
        mainCoordinator?.lockScreenConfrim = { [weak self] info, address in
            DispatchQueue.main.async {
                self?.showMainFlow(info: info,
                                   address: address,
                                   bottomType: .realTime)
            }
        }
        mainCoordinator?.start(info: info, address: address, bottomType: bottomType)
    }
    
    private func showLockScreenFlow(info: LegInfo? = nil,
                                    address: String? = nil) {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let lockScreenCoordinator = container.makeLockScreenCoordinator(navigationController: navigationController)
        lockScreenCoordinator.routerHandler = { [weak self] router in
            DispatchQueue.main.async {
                // TODO: Router에 따라 값 분기 하기
                self?.showMainFlow(info: info, address: address, bottomType: .realTime)
            }
        }
        lockScreenCoordinator.start()
        self.lockScreenCoordinator = lockScreenCoordinator
    }
    
    private func showLoginFlow() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let loginCoordinator = container.makeLoginCoordinator(navigationController: navigationController)
        loginCoordinator.onFinishWithExistUser = { [weak self] isExist in
            DispatchQueue.main.async {
                isExist ? self?.showMainFlow() : self?.showOnboardingFlow()
            }
        }
        loginCoordinator.start()
        self.loginCoordinator = loginCoordinator
    }
    
    private func showOnboardingFlow() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let onboardingCoordinator = container.makeOnboardingCoordinator(navigationController: navigationController)
        onboardingCoordinator.onFinish = { [weak self] success in
            DispatchQueue.main.async {
                success ? self?.showMainFlow() : self?.showLoginFlow()
            }
        }
        
        onboardingCoordinator.start()
        self.onboardingCoordinator = onboardingCoordinator
    }
}
