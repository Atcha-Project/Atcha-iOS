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
        return CourseSearchViewModel(courseUseCase: courseUseCase, startLat: startLat, startLon: startLon, startAddress: startAddress)
    }
    
    func makeCourseSearchViewController(viewModel: CourseSearchViewModel) -> UIViewController {
        return CourseSearchViewController(viewModel: viewModel)
    }
    
    func makeCourseModifyViewModel() -> CourseModifyViewModel {
        return CourseModifyViewModel(searchAddressUseCase: searchAddressUseCase, authorizationUseCase: requestUseCase, locationStateHolder: locationStateHolder)
    }
    
    func makeCourseModifyViewController() -> UIViewController {
        return CourseModifyViewController(viewModel: makeCourseModifyViewModel())
    }
    
    func makeCourseSettingViewModel(location: Location) -> CourseSettingViewModel {
        return CourseSettingViewModel(initialLocation: location, authorizationUseCase: requestUseCase, streamUseCase: streamUseCase, searchAddressUseCase: searchAddressUseCase, locationStateHolder: locationStateHolder)
    }
    
    func makeCourseSettingViewController(viewModel: CourseSettingViewModel) -> UIViewController {
        return CourseSettingViewController(viewModel: viewModel)
    }
}
