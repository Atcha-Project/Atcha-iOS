//
//  MyPageDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/21/25.
//

import UIKit
import Foundation

final class MyPageDIContainer {
    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func makeMyPageViewModel() -> MyPageViewModel {
        MyPageViewModel()
    }
    
    func makeMyPageViewController(viewModel: MyPageViewModel) -> MyPageViewController {
        return MyPageViewController(viewModel: viewModel)
    }

    func makeMyPageCoordinator(navigationController: UINavigationController) -> MyPageCoordinator {
        MyPageCoordinator(navigationController: navigationController,
                          diContainer: self)
    }
}
