//
//  HomeRegistrationCoordinator.swift
//  Atcha-iOS
//
//  Created by wodnd on 3/12/26.
//

import Foundation
import UIKit
import Combine

final class HomeRegistrationCoordinator {
    private let navigationController: UINavigationController
    private let diContainer: HomeRegisterDIContainer // 전용 컨테이너로 교체
    private var cancellables = Set<AnyCancellable>()
    
    var onFinish: (() -> Void)?
    
    init(navigationController: UINavigationController,
         diContainer: HomeRegisterDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start() {
        // 메인에서 진입했으므로 context를 .home(또는 해당되는 케이스)으로 주입
        let viewModel = diContainer.makeHomeRegisterViewModel(context: .home)
        
        viewModel.routeHandler = { [weak self] route in
            self?.handleHomeRouter(route)
        }
        
        let viewController = diContainer.makeHomeRegisterViewController(viewModel: viewModel)
        
        // Root인 이 화면에서 뒤로갈 때만 코디네이터 종료 알림
        viewController.onBackTapped = { [weak self] in
            guard let self = self else { return }
            self.navigationController.popViewController(animated: true)
            self.onFinish?()
        }
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func handleHomeRouter(_ route: HomeRouter) {
        switch route {
        case .searchAdress:
            showSearchAddress()
        case let .homeRegister(useDeviceLocation):
            showHomeFind(useDeviceLocation: useDeviceLocation)
        }
    }
    
    private func showSearchAddress() {
        let viewModel = diContainer.makeHomeSearchViewModel()
        viewModel.routeHandler = { [weak self] route in
            self?.handleHomeRouter(route)
        }
        
        let viewController = diContainer.makeHomeSearchViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showHomeFind(useDeviceLocation: Bool) {
        let viewModel = diContainer.makeHomeFindViewModel(context: .home)
        viewModel.forceDeviceLocation = useDeviceLocation
        
        viewModel.routeHandler = { [weak self] route in
            self?.handleHomeRouter(route)
        }
        
        let viewController = diContainer.makeHomeFindViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
