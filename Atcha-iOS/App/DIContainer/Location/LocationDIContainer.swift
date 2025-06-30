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

        return MapViewModel(requestUseCase: requestUseCase,
                            streamUseCase: streamUseCase)
    }

    func makeMapViewController() -> UIViewController {
        let wrapper = TMapWrapper(frame: UIScreen.main.bounds)
        return MapViewController(viewModel: makeLocationViewModel(),
                                 mapWrapper: wrapper)
    }
    
    func makeMainCoordinator(navigationController: UINavigationController) -> MainCoordinator {
        MainCoordinator(navigationController: navigationController,
                        diContainer: self)
    }
}
