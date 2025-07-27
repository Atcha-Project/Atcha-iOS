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
        
        viewModel.onLocationConfirmed = { [weak self] locationInfo, coordinate in
            guard let self else { return }
            let vm = diContainer.makeCourseSearchViewModel(startLat: "\(coordinate.latitude)",
                                                           startLon: "\(coordinate.longitude)",
                                                           startAddress: locationInfo.name ?? "주소 없음")
            //                self?.showCourseSearch(
            //                    startLat: "\(coordinate.latitude)",
            //                    startLon: "\(coordinate.longitude)",
            //                    startAddress: locationInfo.name ?? "주소 없음"
            //                )
            showCourseSearch(viewModel: vm)
        }
        
        let viewController = CourseModifyViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func showCourseSetting(location: Location) {
        let vm = diContainer.makeCourseSettingViewModel(location: location)
        vm.onTapLocationButton = { [weak self] locationInfo, coordinate in
            print("사용자가 선택한 위치: \(locationInfo.name ?? "없음")")
            
            self?.navigationController.popViewController(animated: true)
            
            if let modifyVC = self?.navigationController.viewControllers.compactMap({ $0 as? CourseModifyViewController }).last {
                modifyVC.didReceiveLocation(locationInfo: locationInfo, coordinate: coordinate)
            }
        }
        let vc = diContainer.makeCourseSettingViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showCourseSearch(viewModel: CourseSearchViewModel) {
        let vc = diContainer.makeCourseSearchViewController(viewModel: viewModel)
        navigationController.pushViewController(vc, animated: true)
    }
}
