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
    private let locationStateHolder: LocationStateHolder
    
    private lazy var homeDI: HomeRegisterDIContainer = {
        HomeRegisterDIContainer(apiService: apiService, locationStateHolder: locationStateHolder)
    }()
    private lazy var pushDI: PushRegisterDIContainer = {
        PushRegisterDIContainer(apiService: apiService, locationStateHolder: locationStateHolder)
    }()
    
    init(apiService: APIService,
         locationStateHolder: LocationStateHolder) {
        self.apiService = apiService
        self.locationStateHolder = locationStateHolder
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

extension MyPageDIContainer {
    func makeHomeRegisterViewModel() -> HomeRegisterViewModel { homeDI.makeHomeRegisterViewModel() }
    func makeHomeRegisterViewController(viewModel: HomeRegisterViewModel) -> HomeRegisterViewController {
        homeDI.makeHomeRegisterViewController(viewModel: viewModel)
    }
    
    func makeHomeFindViewModel() -> HomeFindViewModel { homeDI.makeHomeFindViewModel() }
    func makeHomeFindViewController(viewModel: HomeFindViewModel) -> HomeFindViewController {
        homeDI.makeHomeFindViewController(viewModel: viewModel)
    }
    
    func makeHomeSearchViewModel() -> SearchLocationViewModel { homeDI.makeHomeSearchViewModel() }
    func makeHomeSearchViewController(viewModel: SearchLocationViewModel) -> SearchLocationViewController {
        homeDI.makeHomeSearchViewController(viewModel: viewModel)
    }
}

extension MyPageDIContainer {
    func makePushAlarmViewModel() -> PushAlarmViewModel { pushDI.makePushRegisterViewModel() }
    func makePushAlarmViewController(viewModel: PushAlarmViewModel) -> PushAlarmViewController {
        pushDI.makePushRegisterViewController(viewModel: viewModel)
    }
}
