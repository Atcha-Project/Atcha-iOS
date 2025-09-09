//
//  MyPageCoordinator.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/22/25.
//

import Foundation
import UIKit
import Combine

final class MyPageCoordinator {
    var navigationController: UINavigationController
    private var cancellables = Set<AnyCancellable>()
    private let diContainer: MyPageDIContainer
    private let router: MyPageRouter
    private var myPageViewModelRef: MyPageViewModel?
    
    var signoutFinish: (() -> Void)?
    
    init(navigationController: UINavigationController,
         diContainer: MyPageDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
        self.router = DefaultMyPageRouter(navigationController: navigationController)
    }
    
    func start() {
        let viewModel = diContainer.makeMyPageViewModel()
        self.myPageViewModelRef = viewModel
        let viewController = MyPageViewController(viewModel: viewModel)
        bind(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func bind(viewModel: MyPageViewModel) {
        viewModel.navigationTarget
            .receive(on: DispatchQueue.main)
            .sink { [weak self] target in
                self?.navigate(to: target)
            }
            .store(in: &cancellables)
    }
    
    private func navigate(to target: MyPageNavigationTarget) {
        switch target {
        case .banner:
            let vc = WebViewController(type: .form)
            navigationController.pushViewController(vc, animated: true)
        case .account:
            let vm = diContainer.makeMyAccountViewModel()
            vm.logout = { [weak self] in
                self?.signoutFinish?()
            }
            vm.signOutFinish = { [weak self] in
                self?.showWithdraw()
            }
            let vc = diContainer.makeMyAccountViewController(viewModel: vm)
            navigationController.pushViewController(vc, animated: true)
        case .home:
            let vm = diContainer.makeHomeRegisterViewModel()
            vm.routeHandler = { [weak self] route in
                self?.handleHomeRegisterRoute(route)
            }
            let vc = diContainer.makeHomeRegisterViewController(viewModel: vm)
            navigationController.pushViewController(vc, animated: true)
        case .notification:
            //            let vm = diContainer.makeAlarmSettingViewModel()
            //            vm.onItemSelected = { [weak self] item in
            //                switch item {
            //                case .frequent:
            //                    self?.showPushAlarm()
            //                case .soundType:
            //                    let soundTypeVM = AlarmSoundTypeViewModel()
            //                    let soundTypeVC = AlarmSoundTypeViewController(viewModel: soundTypeVM)
            //                    self?.navigationController.pushViewController(soundTypeVC, animated: true)
            //                }
            //            }
            //            let vc = diContainer.makeAlarmSettingViewController(viewModel: vm)
            
            let vm = diContainer.makePushAlarmViewModel(context: .myPage)
            let vc = diContainer.makePushAlarmViewController(viewModel: vm)
            vc.onSettingComplete = { [weak self] didChange in
                guard let self, didChange else { return }
                self.myPageViewModelRef?.didChangeAlarmSetting = true
            }
            navigationController.pushViewController(vc, animated: true)
        case .term:
            let vc = WebViewController(type: .term)
            navigationController.pushViewController(vc, animated: true)
        case .versionUpdate:
            router.openAppStore()
        }
    }
    
    private func handleHomeRegisterRoute(_ route: HomeRouter) {
        switch route {
        case .searchAdress:
            showSearchAddress()
        case let .homeRegister(useDeviceLocation):
            showHomeFind(useDeviceLocation: useDeviceLocation)
        default: do {}
        }
    }
    
    private func showSearchAddress() {
        let vm = diContainer.makeHomeSearchViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = diContainer.makeHomeSearchViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showHomeFind(useDeviceLocation: Bool) {
        let vm = diContainer.makeHomeFindViewModel()
        vm.forceDeviceLocation = useDeviceLocation
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = diContainer.makeHomeFindViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func handle(route: HomeRouter) {
        switch route {
        case let .homeRegister(useDeviceLocation):
            showHomeFind(useDeviceLocation: useDeviceLocation)
        case .searchAdress:
            showSearchAddress()
        default: do {}
        }
    }
    
    private func showWithdraw() {
        let vm = diContainer.makeWithdrawViewModel()
        vm.signOutFinish = { [weak self] in
            self?.signoutFinish?()
        }
        let vc = diContainer.makeWithdrawViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showPushAlarm() {
        let vm = diContainer.makePushAlarmViewModel(context: .myPage)
        let vc = diContainer.makePushAlarmViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
}
