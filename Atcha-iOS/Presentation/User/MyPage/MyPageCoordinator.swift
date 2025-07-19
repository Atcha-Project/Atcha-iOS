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

    var signoutFinish: (() -> Void)?
    
    init(navigationController: UINavigationController,
         diContainer: MyPageDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
        self.router = DefaultMyPageRouter(navigationController: navigationController)
    }

    func start() {
        let viewModel = diContainer.makeMyPageViewModel()
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
        case .account:
            let vm = diContainer.makeMyAccountViewModel()
            vm.signOutFinish = { [weak self] in self?.signoutFinish?() }
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
            let vm = diContainer.makeAlarmSettingViewModel()
            let vc = diContainer.makeAlarmSettingViewController(viewModel: vm)
            navigationController.pushViewController(vc, animated: true)
        case .term:
            let vc = WebViewController(viewModel: BaseViewModel())
            navigationController.pushViewController(vc, animated: true)
        case .versionUpdate:
            router.openAppStore()
        }
    }
    
    private func handleHomeRegisterRoute(_ route: HomeRouter) {
        switch route {
        case .searchAdress:
            showSearchAddress()
        case .homeRegister:
            showHomeFind()
        default: do {}
        }
    }
    
    private func showSearchAddress() {
        let vm = diContainer.makeHomeSearchViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = diContainer.makeHomeSearchViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showHomeFind() {
        let vm = diContainer.makeHomeFindViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = diContainer.makeHomeFindViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func handle(route: HomeRouter) {
        switch route {
        case .homeRegister:
            showHomeFind()
        case .searchAdress:
            showSearchAddress()
        default: do {}
        }
    }
}
