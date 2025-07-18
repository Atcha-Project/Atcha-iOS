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
    private lazy var searchAddressUseCase = SearchAddressUseCaseImpl(repository: AddressRepositoryImpl(apiService: apiService))
    private lazy var requestUseCase = RequestLocationAuthorizationUseCaseImpl(repository: PermissionRepositoryImpl())
    
    private lazy var myPageDI: MyPageDIContainer = {
        MyPageDIContainer(apiService: apiService,
                          locationStateHolder: locationStateHolder)
    }()
    
    init(apiService: APIService, locationStateHolder: LocationStateHolder) {
        self.apiService = apiService
        self.locationStateHolder = locationStateHolder
    }
    
    func makeMainiewModel() -> MainViewModel {
        let streamUseCase = ObserLocationStreamUseCaseImpl(repository: LocationStreamRepositoryImpl())
        let fetchTaxiFareUseCase = FetchTaxiFareUseCaseImpl(repository: FetchTaxiFareRepositoryImpl(apiService: apiService))
        
        return MainViewModel(authorizationUseCase: requestUseCase,
                             streamUseCase: streamUseCase,
                             fetchTaxiFareUseCase: fetchTaxiFareUseCase,
                             searchAddressUseCase: searchAddressUseCase,
                             locationStateHolder: locationStateHolder)
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

// MARK: - Cousre
extension MainDIContainer {
    func makeCourseSearchViewModel(startLat: String, startLon: String, startAddress: String) -> CourseSearchViewModel {
        let courseUseCase = CourseUseCaseImpl(repository: CourseRepositoryImpl(apiService: apiService))
        return CourseSearchViewModel(courseUseCase: courseUseCase, startLat: startLat, startLon: startLon, startAddress: startAddress)
    }
    
    func makeCourseSearchViewController(startLat: String, startLon: String, startAddress: String) -> UIViewController {
        let viewModel = makeCourseSearchViewModel(startLat: startLat, startLon: startLon, startAddress: startAddress)
        return CourseSearchViewController(viewModel: viewModel)
    }
    
    func makeCourseModifyViewModel() -> CourseModifyViewModel {
        return CourseModifyViewModel(searchAddressUseCase: searchAddressUseCase, authorizationUseCase: requestUseCase, locationStateHolder: locationStateHolder)
    }
    
    func makeCourseModifyViewController() -> UIViewController {
        return CourseModifyViewController(viewModel: makeCourseModifyViewModel())
    }
}
