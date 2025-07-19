//
//  OnboardingDIContainer.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import UIKit
import Foundation

final class OnboardingDIContainer {
    private let apiService: APIService
    private let locationStateHolder: LocationStateHolder
    
    private lazy var homeDI: HomeRegisterDIContainer = {
        HomeRegisterDIContainer(apiService: apiService, locationStateHolder: locationStateHolder)
    }()
    
    private lazy var pushDI: PushRegisterDIContainer = {
        PushRegisterDIContainer(apiService: apiService, locationStateHolder: locationStateHolder)
    }()

    private lazy var permissionDI: PermissionDIContainer = {
        PermissionDIContainer(locationStateHolder: locationStateHolder)
    }()
    
    init(apiService: APIService,
         locationStateHolder: LocationStateHolder) {
        self.apiService = apiService
        self.locationStateHolder = locationStateHolder
    }
    
    func makeHomeRegisterViewModel() -> HomeRegisterViewModel { homeDI.makeHomeRegisterViewModel(context: .onboarding) }
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
    
    func makePushAlarmViewModel() -> PushAlarmViewModel { pushDI.makePushRegisterViewModel() }
    func makePushAlarmViewController(viewModel: PushAlarmViewModel) -> PushAlarmViewController {
        pushDI.makePushRegisterViewController(viewModel: viewModel)
    }
    
    func makePermissionViewModel() -> PermissionViewModel { permissionDI.makePermissionViewModel() }
    func makePermissionViewController(viewModel: PermissionViewModel) -> PermissionViewController {
        permissionDI.makePermissionViewController(viewModel: viewModel)
    }
    
    func makeOnboardingCoordinator(navigationController: UINavigationController) -> OnboardingCoordinator {
        return OnboardingCoordinator(apiService: apiService,
                                     navigationController: navigationController,
                                     locationHolder: locationStateHolder,
                                     diContainer: self)
    }
}
