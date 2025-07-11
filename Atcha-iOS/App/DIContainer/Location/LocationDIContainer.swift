//
//  LocationDIContainer.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import UIKit
import Foundation

final class LocationDIContainer {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func makeLocationViewModel() -> MapViewModel {
        let streamUseCase = ObserLocationStreamUseCaseImpl(repository: LocationStreamRepositoryImpl())
        let requestUseCase = RequestLocationAuthorizationUseCaseImpl(repository: RequestLocationAuthorizationRepositoryImpl())
        let searchAddressUseCase = SearchAddressUseCaseImpl(repository: AddressRepositoryImpl(apiService: apiService))
        let fetchTaxiFareUseCase = FetchTaxiFareUseCaseImpl(repository: FetchTaxiFareRepositoryImpl(apiService: apiService))
        
        return MapViewModel(authorizationUseCase: requestUseCase,
                            streamUseCase: streamUseCase,
                            fetchTaxiFareUseCase: fetchTaxiFareUseCase,
                            searchAddressUseCase: searchAddressUseCase)
    }
    
    func makeMapViewController() -> UIViewController {
        return MapViewController(viewModel: makeLocationViewModel())
    }
    
    func makeCourseSearchViewModel(startLat: String, startLon: String, startAddress: String) -> CourseSearchViewModel {
        let courseUseCase = CourseUseCaseImpl(repository: CourseRepositoryImpl(apiService: apiService))
        return CourseSearchViewModel(courseUseCase: courseUseCase, startLat: startLat, startLon: startLon, startAddress: startAddress)
    }
    
    func makeCourseSearchViewController(startLat: String, startLon: String, startAddress: String) -> UIViewController {
        let viewModel = makeCourseSearchViewModel(startLat: startLat, startLon: startLon, startAddress: startAddress)
        return CourseSearchViewController(viewModel: viewModel)
    }
    
    func makeMainCoordinator(navigationController: UINavigationController) -> MainCoordinator {
        MainCoordinator(navigationController: navigationController,
                        diContainer: self)
    }
}
