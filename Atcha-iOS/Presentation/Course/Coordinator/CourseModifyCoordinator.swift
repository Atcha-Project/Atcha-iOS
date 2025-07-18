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
        vm.onTapLocationButton = { [weak self] locationInfo, coordinate in
            print("사용자가 선택한 위치: \(locationInfo.name ?? "없음") / \(locationInfo.address ?? "없음")")
            print("좌표: \(coordinate.latitude), \(coordinate.longitude)")
            
            self?.navigationController.popViewController(animated: true)
            if let name = locationInfo.name {
                self?.showCourseSearch(startLat: "\(coordinate.latitude)", startLon: "\(coordinate.longitude)", startAddress: "\(name)")
            }
        }
        let vc = diContainer.makeCourseSettingViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showCourseSearch(startLat: String, startLon: String, startAddress: String) {
        let vc = diContainer.makeCourseSearchViewController(startLat: startLat, startLon: startLon, startAddress: startAddress)
        navigationController.pushViewController(vc, animated: true)
    }
    
}
