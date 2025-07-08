//
//  CourseDIContainer.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/7/25.
//

import Foundation
import UIKit

final class CourseDIContainer {
    private let apiService: APIService
    
    init(apiService: APIService) {
        self.apiService = apiService
    }
    
    func makeCourseUseCase() -> CourseUseCase {
        let repository: CourseRepository = CourseRepositoryImpl(apiService: apiService)
        
        return CourseUseCaseImpl(repository: repository)
    }
    
    func makeCourseSearchViewModel() -> CourseSearchViewModel {
        CourseSearchViewModel(courseUseCase: makeCourseUseCase(), startLat: "37.554722", startLon: "126.970833", startAddress: "서울역")
    }
    
    func makeCourseModifyViewModel() {
        
    }
    
    func makeCourseCoordinator(navigationController: UINavigationController) -> CourseCoordinator {
        CourseCoordinator(navigationController: navigationController, diContainer: self)
    }
}
