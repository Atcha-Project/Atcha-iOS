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
    var busDetailCoordinator: BusDetailCoordinator?
    
    init(window: UIWindow, container: AppDIContainer) {
        self.window = window
        self.container = container
    }
    
    func startApp() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
//        let splashCoordinator = container.makeSplashCoordinator(navigationController: navigationController)
//        splashCoordinator.routerHandler = { [weak self] router in
//            guard let self else { return }
//            switch router {
//            case .login:
//                showLoginFlow()
//            case .main:
//                showMainFlow()
//            case .onboarding:
//                showOnboardingFlow()
//            }
//        }
//        splashCoordinator.start()
//        self.splashCoordinator = splashCoordinator
        
        
        let apiService = container.networkDIContainer.makeAPIService()
        let busInfoDI = BusInfoDIContainer(apiService: apiService)
        
        let busDetailCoordinator = BusDetailCoordinator(
            navigationController: navigationController,
            diContainer: busInfoDI
        )
        
        // ✅ 더미 데이터 (테스트용)
        let dummyBusDetailInfo = BusDetailInfo(
            routeName: "간선:402",
            start: addressInfo(name: "시청앞.덕수궁",
                               lon: 126.97695277777778, lat: 37.566005555555556),
            passStations: [
                PassStations(index: 0, stationName: "시청앞.덕수궁", lat: "37.566006", lon: "126.976953"),
                PassStations(index: 1, stationName: "시청서소문2청사", lat: "37.562819", lon: "126.976228"),
                PassStations(index: 2, stationName: "서울역버스환승센터(5번승강장)(중)", lat: "37.555481", lon: "126.972689"),
            ])
        self.busDetailCoordinator = busDetailCoordinator
        busDetailCoordinator.start(busDetailInfo: dummyBusDetailInfo)
    }
    
    private func showMainFlow() {
        let navigationController = UINavigationController()
        window.rootViewController = navigationController
        mainCoordinator = container.makeMainCoordinator(navigationController: navigationController)
        mainCoordinator?.signoutFinish = { [weak self] in
            DispatchQueue.main.async {
                self?.showLoginFlow()
            }
        }
        mainCoordinator?.start()
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


