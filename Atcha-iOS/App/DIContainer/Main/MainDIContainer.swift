//
//  MainDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import UIKit
import Foundation

final class MainDIContainer {
    private let apiService: APIService
    private let locationStateHolder: LocationStateHolder
    private let tokenStorage: TokenStorage
    
    private lazy var searchAddressUseCase = SearchAddressUseCaseImpl(repository: AddressRepositoryImpl(apiService: apiService))
    private lazy var requestUseCase = RequestLocationAuthorizationUseCaseImpl(repository: PermissionRepositoryImpl())
    private lazy var streamUseCase = ObserLocationStreamUseCaseImpl(repository: LocationStreamRepositoryImpl())
    private lazy var busInfoUseCase = BusInfoUseCaseImpl(repository: BusInfoRepositoryImpl(apiService: apiService))
    private lazy var alarmUseCase = AlarmUseCaseImpl(repository: AlarmRepositoryImpl(apiService: apiService))
    private lazy var courseUseCase = CourseUseCaseImpl(repository: CourseRepositoryImpl(apiService: apiService))
    
    private lazy var myPageDI: MyPageDIContainer = {
        MyPageDIContainer(apiService: apiService,
                          locationStateHolder: locationStateHolder)
    }()
    
    private lazy var courseDI: CourseDIContainer = {
        CourseDIContainer(apiService: apiService,
                          locationStateHolder: locationStateHolder)
    }()
    
    private lazy var rotueDI: RouteDIContainer = {
        RouteDIContainer(apiService: apiService)
    }()
    
    private lazy var busInfoDI: BusInfoDIContainer = {
        BusInfoDIContainer(apiService: apiService)
    }()
    
    private lazy var proximityDI: ProximityDIContainer = {
        ProximityDIContainer(apiService: apiService)
    }()
    
    private lazy var lockScreenDI: LockScreenDIContainer = {
        LockScreenDIContainer(apiService: apiService)
    }()
    
    private lazy var loginDI: LoginDIContainer = {
            LoginDIContainer(apiService: apiService, tokenStorage: tokenStorage)
        }()
    
    private lazy var homeRegisterDI: HomeRegisterDIContainer = {
        HomeRegisterDIContainer(apiService: apiService, locationStateHolder: locationStateHolder, tokenStorage: tokenStorage)
    }()
    
    init(apiService: APIService, locationStateHolder: LocationStateHolder, tokenStorage: TokenStorage) { 
            self.apiService = apiService
            self.locationStateHolder = locationStateHolder
            self.tokenStorage = tokenStorage
        }
    
    func makeMainiewModel() -> MainViewModel {
        let fetchTaxiFareUseCase = FetchTaxiFareUseCaseImpl(repository: FetchTaxiFareRepositoryImpl(apiService: apiService))
        return MainViewModel(authorizationUseCase: requestUseCase,
                             streamUseCase: streamUseCase,
                             fetchTaxiFareUseCase: fetchTaxiFareUseCase,
                             searchAddressUseCase: searchAddressUseCase,
                             locationStateHolder: locationStateHolder,
                             busInfoUseCase: busInfoUseCase,
                             alarmUseCase: alarmUseCase,
                             courseUseCase: courseUseCase)
    }
    
    func makeMainViewController(viewModel: MainViewModel) -> UIViewController {
        return MainViewController(viewModel: viewModel)
    }
    
    func makeMainCoordinator(navigationController: UINavigationController) -> MainCoordinator {
        MainCoordinator(navigationController: navigationController,
                        diContainer: self)
    }
}

// MARK: - MyPage
extension MainDIContainer {
    func makeMyPageViewModel() -> MyPageViewModel { myPageDI.makeMyPageViewModel() }
    func makeMyPageViewController(viewModel: MyPageViewModel) -> MyPageViewController {
        myPageDI.makeMyPageViewController(viewModel: viewModel)
    }
    func makeMyPageDIContainer() -> MyPageDIContainer {
        return myPageDI
    }
}

// MARK: - Detail Route
extension MainDIContainer {
    func makeRouteDIContainer() -> RouteDIContainer {
        return rotueDI
    }
}

// MARK: - Lock Screen
extension MainDIContainer {
    func makeLockScreenDIContainer() -> LockScreenDIContainer {
        return lockScreenDI
    }
}

// MARK: - Cousre
extension MainDIContainer {
    func makeCourseDIContainer() -> CourseDIContainer {
        return courseDI
    }
}

// MARK: - BusInfo
extension MainDIContainer {
    func makeBusInfoDIContainer() -> BusInfoDIContainer {
        return busInfoDI
    }
}

// MARK: - Proximity
extension MainDIContainer{
    func makeProximityDIContainer() -> ProximityDIContainer {
        return proximityDI
    }
}

// MARK: - Login
extension MainDIContainer{
    func makeLoginDIContainer() -> LoginDIContainer {
        return loginDI
    }
}


// MARK: - HomeRegister
extension MainDIContainer{
    func makeHomeRegisterDIContainer() -> HomeRegisterDIContainer {
        return homeRegisterDI
    }
}
