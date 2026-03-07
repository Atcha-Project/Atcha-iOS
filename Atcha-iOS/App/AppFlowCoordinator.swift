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
    
    // 메모리 유지를 위한 Coordinator 참조
    private var splashCoordinator: SplashCoordinator?
    private var mainCoordinator: MainCoordinator?
    private var onboardingCoordinator: OnboardingCoordinator?
    private var lockScreenCoordinator: LockScreenCoordinator?
    private var introCoordinator: IntroCoordinator?
    
    
    init(window: UIWindow, container: AppDIContainer) {
        self.window = window
        self.container = container
    }
    
    func startApp() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        // 세션 만료 시: 모든 뷰를 엎고 다시 앱 시작
        SessionController.shared.routeToLogin = { [weak self] in
            DispatchQueue.main.async {
                AppDIContainer.shared.tokenStorage.clearAllTokens()
                UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.hasSeenIntro.rawValue)
                self?.startApp()
            }
        }
        
        let splashCoordinator = container.makeSplashCoordinator(navigationController: navigationController)
        splashCoordinator.routerHandler = { [weak self] router in
            guard let self = self else { return }
            switch router {
            case .intro:
                showIntroFlow()
            case .main:
                showMainFlow()
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
        
        let mainCoordinator = container.makeMainCoordinator(navigationController: navigationController)
        self.mainCoordinator = mainCoordinator
        
        // [신규 유저 온보딩 흐름]
        // Main 화면(지도)을 깔아둔 상태에서, 그 위(Navigation 스택)에 온보딩을 얹습니다.
        mainCoordinator.routeToOnboarding = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                let onboardingCoordinator = self.container.makeOnboardingCoordinator(navigationController: navigationController)
                
                // 온보딩(회원가입)이 성공적으로 끝났을 때
                onboardingCoordinator.onFinish = { [weak self] success in
                    DispatchQueue.main.async {
                        // 위에 쌓여있던 온보딩 화면들을 싹 치우고 밑에 깔려있던 Main(지도)으로 복귀!
                        navigationController.popToRootViewController(animated: true)
                        
                        // 집 주소가 등록되었으니, MainVC를 찔러서 현위치/마커를 새로고침하게 합니다.
                        if let mainVC = navigationController.viewControllers.first as? MainViewController {
                            mainVC.viewModel.setupLocation()
                            mainVC.shouldShowWelcomeToast = true
                        }
                        
                        self?.onboardingCoordinator = nil
                    }
                }
                
                onboardingCoordinator.start()
                self.onboardingCoordinator = onboardingCoordinator // 메모리 유지
            }
        }
        
        // [락스크린 확인 흐름]
        mainCoordinator.lockScreenConfrim = { [weak self] info, address in
            DispatchQueue.main.async {
                if let info, let address {
                    self?.showMainFlow(info: info, address: address, bottomType: .detail)
                } else {
                    self?.showMainFlow()
                }
            }
        }
        
        // [회원 탈퇴 흐름]
        mainCoordinator.withdrawFinish = { [weak self] in
            DispatchQueue.main.async {
                // 앱 데이터를 다 지웠으니, 스플래시부터 앱을 아예 새로 시작(리부팅)합니다!
                self?.startApp()
            }
        }
        
        mainCoordinator.start(info: info, address: address, bottomType: bottomType)
    }
    
    private func showLockScreenFlow(info: LegInfo? = nil,
                                    address: String? = nil) {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let lockScreenCoordinator = container.makeLockScreenCoordinator(navigationController: navigationController)
        lockScreenCoordinator.routerHandler = { [weak self] router in
            DispatchQueue.main.async {
                switch router {
                case .lockScreen(let info, let address):
                    if let info, let address {
                        self?.showMainFlow(info: info, address: address, bottomType: .departure)
                    } else {
                        self?.showMainFlow()
                    }
                default: do {}
                }
            }
        }
        lockScreenCoordinator.start()
        self.lockScreenCoordinator = lockScreenCoordinator
    }
    
    private func showIntroFlow() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        
        let introCoordinator = container.makeIntroCoordinator(navigationController: navigationController)
        
        // 인트로에서 "게스트 모드로 시작하기" 등을 눌렀을 때 지도(Main)로 넘어갑니다.
        introCoordinator.onFinishWithGuest = { [weak self] in
            DispatchQueue.main.async {
                UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.hasSeenIntro.rawValue)
                self?.showMainFlow()
            }
        }
        
        introCoordinator.start()
        self.introCoordinator = introCoordinator
    }
}
