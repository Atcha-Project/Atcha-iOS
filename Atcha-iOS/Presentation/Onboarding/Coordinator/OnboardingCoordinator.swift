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
    private let apiService: APIService
    private let locationHolder: LocationStateHolder
    
    private let homeDIConatiner: HomeRegisterDIContainer
    private let pushRegisterDIContainer: PushRegisterDIContainer
    private let permissionDIConatiner: PermissionDIContainer
    
    var onFinish: ((Bool) -> Void)?
    var routeHandler: ((OnboardingRoute) -> Void)?
    
    init(apiService: APIService,
         navigationController: UINavigationController,
         locationHolder: LocationStateHolder,
         homeDIConatiner: HomeRegisterDIContainer,
         pushRegisterDIContainer: PushRegisterDIContainer,
         permissionDIConatiner: PermissionDIContainer) {
        self.apiService = apiService
        self.navigationController = navigationController
        self.homeDIConatiner = homeDIConatiner
        self.pushRegisterDIContainer = pushRegisterDIContainer
        self.permissionDIConatiner = permissionDIConatiner
        self.locationHolder = locationHolder
    }
    
    func start() {
        showHomeRegister()
    }
    
    private func showHomeRegister() {
        let vm = homeDIConatiner.makeHomeRegisterViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = homeDIConatiner.makeHomeRegisterViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showHomeFind() {
        let vm = homeDIConatiner.makeHomeFindViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = homeDIConatiner.makeHomeFindViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showSearchAddress() {
        let vm = homeDIConatiner.makeHomeSearchViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = homeDIConatiner.makeHomeSearchViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showPushRegister() {
        let vm = pushRegisterDIContainer.makePushRegisterViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        vm.onFinish = { [weak self] isSuccess in self?.onFinish?(isSuccess) }
        let vc = pushRegisterDIContainer.makePushRegisterViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showPermission() {
        let vc = permissionDIConatiner.makePermissionViewController()
        navigationController.presentPanModal(vc)
    }
    
    private func handle(route: OnboardingRoute) {
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
