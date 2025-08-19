//
//  CourseDIContainer.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/18/25.
//

import Foundation
import UIKit

final class CourseDIContainer {
    private let apiService: APIService
    private let locationStateHolder: LocationStateHolder
    private lazy var searchAddressUseCase = SearchAddressUseCaseImpl(repository: AddressRepositoryImpl(apiService: apiService))
    private lazy var requestUseCase = RequestLocationAuthorizationUseCaseImpl(repository: PermissionRepositoryImpl())
    private lazy var streamUseCase = ObserLocationStreamUseCaseImpl(repository: LocationStreamRepositoryImpl())
    
    init(apiService: APIService, locationStateHolder: LocationStateHolder) {
        self.apiService = apiService
        self.locationStateHolder = locationStateHolder
    }
    
    func makeCourseSearchViewModel(startLat: String, startLon: String, startAddress: String) -> CourseSearchViewModel {
        let courseUseCase = CourseUseCaseImpl(repository: CourseRepositoryImpl(apiService: apiService))
        let alarmUseCase = AlarmUseCaseImpl(repository: AlarmRepositoryImpl(apiService: apiService))
        return CourseSearchViewModel(courseUseCase: courseUseCase,
                                     alarmUseCase: alarmUseCase,
                                     startLat: startLat,
                                     startLon: startLon,
                                     startAddress: startAddress)
    }
    
    func makeCourseSearchViewController(viewModel: CourseSearchViewModel) -> UIViewController {
        return CourseSearchViewController(viewModel: viewModel)
    }
    
    func makeCourseModifyViewModel(location: Location) -> CourseModifyViewModel {
        return CourseModifyViewModel(searchAddressUseCase: searchAddressUseCase, authorizationUseCase: requestUseCase, locationStateHolder: locationStateHolder, initialLocation: location)
    }
    
    func makeCourseModifyViewController(viewModel: CourseModifyViewModel) -> UIViewController {
        return CourseModifyViewController(viewModel: viewModel)
    }
    
    func makeCourseSettingViewModel(location: Location) -> CourseSettingViewModel {
        return CourseSettingViewModel(initialLocation: location, authorizationUseCase: requestUseCase, streamUseCase: streamUseCase, searchAddressUseCase: searchAddressUseCase, locationStateHolder: locationStateHolder)
    }
    
    func makeCourseSettingViewController(viewModel: CourseSettingViewModel) -> UIViewController {
        return CourseSettingViewController(viewModel: viewModel)
    }
}
