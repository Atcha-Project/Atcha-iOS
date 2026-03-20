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
    private let tokenStorage: TokenStorage
    
    private lazy var homeDI: HomeRegisterDIContainer = {
        HomeRegisterDIContainer(apiService: apiService,
                                locationStateHolder: locationStateHolder,
                                tokenStorage: tokenStorage)
    }()
    
    private lazy var pushDI: PushRegisterDIContainer = {
        PushRegisterDIContainer(apiService: apiService,
                                locationStateHolder: locationStateHolder,
                                tokenStorage: tokenStorage)
    }()
    
    private lazy var permissionDI: PermissionDIContainer = {
        PermissionDIContainer(locationStateHolder: locationStateHolder)
    }()
    
    init(apiService: APIService,
         locationStateHolder: LocationStateHolder,
         tokenStorage: TokenStorage) {
        self.apiService = apiService
        self.locationStateHolder = locationStateHolder
        self.tokenStorage = tokenStorage
    }
    
    func makeHomeRegisterViewModel() -> HomeRegisterViewModel { homeDI.makeHomeRegisterViewModel(context: .onboarding) }
    func makeHomeRegisterViewController(viewModel: HomeRegisterViewModel) -> HomeRegisterViewController {
        homeDI.makeHomeRegisterViewController(viewModel: viewModel)
    }
    
    func makeHomeFindViewModel() -> HomeFindViewModel { homeDI.makeHomeFindViewModel(context: .onboarding) }
    func makeHomeFindViewController(viewModel: HomeFindViewModel) -> HomeFindViewController {
        homeDI.makeHomeFindViewController(viewModel: viewModel)
    }
    
    func makeHomeSearchViewModel() -> SearchLocationViewModel { homeDI.makeHomeSearchViewModel() }
    func makeHomeSearchViewController(viewModel: SearchLocationViewModel) -> SearchLocationViewController {
        homeDI.makeHomeSearchViewController(viewModel: viewModel)
    }
    
    func makePushAlarmViewModel(context: PushAlarmContext) -> PushAlarmViewModel { pushDI.makePushRegisterViewModel(context: context) }
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
