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
    private let tokenStorage: TokenStorage
    private let locationStateHolder: LocationStateHolder
    
    var signoutFinish: (() -> Void)?
    
    private lazy var homeDI: HomeRegisterDIContainer = {
        HomeRegisterDIContainer(apiService: apiService, locationStateHolder: locationStateHolder, tokenStorage: tokenStorage)
    }()
    private lazy var pushDI: PushRegisterDIContainer = {
        PushRegisterDIContainer(apiService: apiService, locationStateHolder: locationStateHolder)
    }()
    private lazy var myAccountDI: MyAccountDIContainer = {
        MyAccountDIContainer(apiService: apiService, tokenStorage: tokenStorage, locationStateHolder: locationStateHolder)
    }()
    private lazy var alarmSettingDI: AlarmSettingDIContainer = {
        AlarmSettingDIContainer()
    }()
    
    init(apiService: APIService,
             tokenStorage: TokenStorage,
             locationStateHolder: LocationStateHolder) {
            self.apiService = apiService
            self.tokenStorage = tokenStorage
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

// MARK: Home Register
extension MyPageDIContainer {
    func makeHomeRegisterViewModel() -> HomeRegisterViewModel { homeDI.makeHomeRegisterViewModel(context: .myPage) }
    func makeHomeRegisterViewController(viewModel: HomeRegisterViewModel) -> HomeRegisterViewController {
        homeDI.makeHomeRegisterViewController(viewModel: viewModel)
    }
    
    func makeHomeFindViewModel() -> HomeFindViewModel { homeDI.makeHomeFindViewModel(context: .myPage) }
    func makeHomeFindViewController(viewModel: HomeFindViewModel) -> HomeFindViewController {
        homeDI.makeHomeFindViewController(viewModel: viewModel)
    }
    
    func makeHomeSearchViewModel() -> SearchLocationViewModel { homeDI.makeHomeSearchViewModel() }
    func makeHomeSearchViewController(viewModel: SearchLocationViewModel) -> SearchLocationViewController {
        homeDI.makeHomeSearchViewController(viewModel: viewModel)
    }
}

// MARK: - MyAccount
extension MyPageDIContainer {
    func makeMyAccountViewModel() -> MyAccountViewModel {
        myAccountDI.makeMyAccountViewModel()
    }
    func makeMyAccountViewController(viewModel: MyAccountViewModel) -> MyAccountViewController {
        myAccountDI.makeMyAccountViewController(viewModel: viewModel)
    }
    
    func makeWithdrawViewModel() -> WithdrawViewModel {
        myAccountDI.makeWithdrawViewModel()
    }
    func makeWithdrawViewController(viewModel: WithdrawViewModel) -> WithdrawViewController {
        myAccountDI.makeWithdrawViewController(viewModel: viewModel)
    }
}

// MARK: - Alarm Setting
extension MyPageDIContainer {
    func makeAlarmSettingViewModel() -> AlarmSettingViewModel {
        alarmSettingDI.makeAlarmSettingViewModel()
    }
    func makeAlarmSettingViewController(viewModel: AlarmSettingViewModel) -> AlarmSettingViewController {
        alarmSettingDI.makeAlarmSettingViewController(viewModel: viewModel)
    }
}

extension MyPageDIContainer {
    func makePushAlarmViewModel(context: PushAlarmContext) -> PushAlarmViewModel { pushDI.makePushRegisterViewModel(context: context) }
    func makePushAlarmViewController(viewModel: PushAlarmViewModel) -> PushAlarmViewController {
        pushDI.makePushRegisterViewController(viewModel: viewModel)
    }
}
