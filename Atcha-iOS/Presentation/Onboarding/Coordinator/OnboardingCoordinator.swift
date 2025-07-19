//
//  OnboardingCoordinator.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import UIKit
import Foundation
import CoreLocation
import PanModal

final class OnboardingCoordinator {
    private let navigationController: UINavigationController
    private let diContainer: OnboardingDIContainer
    private let apiService: APIService
    private let locationHolder: LocationStateHolder
    
    var onFinish: ((Bool) -> Void)?
    var routeHandler: ((HomeRouter) -> Void)?
    
    init(apiService: APIService,
         navigationController: UINavigationController,
         locationHolder: LocationStateHolder,
         diContainer: OnboardingDIContainer) {
        self.apiService = apiService
        self.navigationController = navigationController
        self.locationHolder = locationHolder
        self.diContainer = diContainer
    }
    
    func start() {
        showHomeRegister()
    }
    
    private func showHomeRegister() {
        let vm = diContainer.makeHomeRegisterViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = diContainer.makeHomeRegisterViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showHomeFind() {
        let vm = diContainer.makeHomeFindViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = diContainer.makeHomeFindViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showSearchAddress() {
        let vm = diContainer.makeHomeSearchViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = diContainer.makeHomeSearchViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showPushRegister() {
        let vm = diContainer.makePushAlarmViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        vm.onFinish = { [weak self] isSuccess in self?.onFinish?(isSuccess) }
        let vc = diContainer.makePushAlarmViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showPermission() {
        let vm = diContainer.makePermissionViewModel()
        let vc = diContainer.makePermissionViewController(viewModel: vm)
        navigationController.presentPanModal(vc)
    }
    
    private func handle(route: HomeRouter) {
        switch route {
        case .homeRegister:
            showHomeFind()
        case .permission:
            showPermission()
        case .searchAdress:
            showSearchAddress()
        case .pushRegister:
            showPushRegister()
        }
        
        routeHandler?(route)
    }
}
