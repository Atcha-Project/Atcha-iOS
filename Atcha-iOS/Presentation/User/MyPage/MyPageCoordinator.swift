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

    init(navigationController: UINavigationController, diContainer: MyPageDIContainer) {
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
            router.pushAccount()
        case .home:
            router.pushHome()
        case .notification:
            router.pushNotification()
        case .term:
            router.pushTerm()
        case .versionUpdate:
            router.openAppStore()
        }
    }
}
