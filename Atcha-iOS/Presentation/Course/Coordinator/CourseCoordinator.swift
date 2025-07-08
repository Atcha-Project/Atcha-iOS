//
//  CourseCoordinator.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/7/25.
//

import Foundation
import UIKit

final class CourseCoordinator {
    private let navigationController: UINavigationController
    private let diContainer: CourseDIContainer
    
    var onFinish: ((Bool) -> Void)?
    
    init(navigationController: UINavigationController, diContainer: CourseDIContainer, onFinish: ((Bool) -> Void)? = nil) {
        self.navigationController = navigationController
        self.diContainer = diContainer
        self.onFinish = onFinish
    }
    
    func start(){
        let viewModel = diContainer.makeCourseSearchViewModel()
        
        let courseSearchVC = CourseSearchViewController(viewModel: viewModel)
        
        navigationController.pushViewController(courseSearchVC, animated: true)
    }
}
