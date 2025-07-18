//
//  CourseModifyCoordinator.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/18/25.
//

import Foundation
import UIKit
import Combine

final class CourseModifyCoordinator {
    var navigationController: UINavigationController
    private var cancellables = Set<AnyCancellable>()
    private let diContainer: CourseDIContainer

    init(navigationController: UINavigationController,
         diContainer: CourseDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }

    func start() {
        let viewModel = diContainer.makeCourseModifyViewModel()
        viewModel.onLocationSelected = { [weak self] location in
                self?.showCourseSetting(location: location)
            }

        
        let viewController = CourseModifyViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showCourseSetting(location: Location) {
        let vm = diContainer.makeCourseSettingViewModel(location: location)
        let vc = diContainer.makeCourseSettingViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
}
