//
//  OnboardingCoordinator.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/24/25.
//

import UIKit
import Foundation
import CoreLocation

final class OnboardingCoordinator {
    private let navigationController: UINavigationController
    private let diContainer: OnboardingDIContainer
    private let locationHolder: LocationStateHolder
    private let apiService: APIService
    
    var onFinish: ((Bool) -> Void)?
    
    init(apiService: APIService,
         navigationController: UINavigationController,
         disContainer: OnboardingDIContainer,
         locationHolder: LocationStateHolder,
         onFinish: ((Bool) -> Void)? = nil) {
        self.apiService = apiService
        self.navigationController = navigationController
        self.diContainer = disContainer
        self.locationHolder = locationHolder
        self.onFinish = onFinish
    }
    
    func start() {
//        let homeRegiVM = HomeRegisterDIContainer(apiService: apiService,
//                                                 locationStateHolder: locationHolder).makeHomeRegisterViewModel()
        
        let homeRegisterVC = HomeRegisterDIContainer(apiService: apiService,
                                                     locationStateHolder: locationHolder).makeHomeRegisterViewController()
        
        //        let viewModel = diContainer.makeHomeRegisterViewModel()
        //        viewModel.onFinish = { [weak self] success in
        //            self?.onFinish?(success)
        //        }
        
        //        let homeRegisterVC = HomeRegisterViewController(viewModel: viewModel)
        
        // SearchLocation ViewController 이동
        //        homeRegisterVC.onSearchTapped = { [weak self] in
        //            self?.showSearchLocation()
        //        }
        
        // RegisterLocation ViewController 이동
        //        homeRegisterVC.onCurrentTapped = { [weak self] coordinate, placeName, address in
        //            self?.showRegisterLocation(coordinate, placeName, address)
        //        }
        
        // PushAlarm ViewController 이동
        //        homeRegisterVC.onNextTapped = { [weak self] location in
        //            self?.showPushAlarm(with: location)
        //        }
        
        navigationController.pushViewController(homeRegisterVC, animated: true)
    }
    
    private func showPushAlarm(with location: SelectedLocation) {
        let viewModel = diContainer.makePushAlarmViewModel()
        viewModel.selectedLocation = location
        
        viewModel.onFinish = { [weak self] success in
            self?.onFinish?(success)
        }
        
        let pushAlarmVC = PushAlarmViewController(viewModel: viewModel)
        navigationController.pushViewController(pushAlarmVC, animated: true)
    }
    
    private func showSearchLocation() {
//        let viewModel = diContainer.makeSearchLocationViewModel()
//        let searchVC = SearchLocationViewController(viewModel: viewModel)
        
        // RegisterLocation ViewController 이동
//        searchVC.onCurrentTapped = { [weak self] coordinate, placeName, address in
//            self?.showRegisterLocation(coordinate, placeName, address)
//        }
//        
//        navigationController.pushViewController(searchVC, animated: true)
    }
    
    private func showRegisterLocation(
        _ coordinate: CLLocationCoordinate2D,
        _ placeName: String,
        _ address: String
    ) {
        let viewModel = diContainer.makeRegisterLocationViewModel()
        let locationVC = RegisterLocationViewController(
            viewModel: viewModel,
            coordinate: coordinate,
            placeName: placeName,
            address: address
        )
        
        locationVC.onRegisterCompleted = { [weak self] name, address, lat, lon in
            guard let self else { return }
            
            if let homeVC = self.navigationController.viewControllers.first(where: { $0 is HomeRegisterViewController }) as? HomeRegisterViewController {
                
                // ViewModel에 업데이트 메서드를 통해 반영 및 ViewController Pop
                //                homeVC.viewModel.updateLocation(
                //                    name: name,
                //                    address: address,
                //                    lat: lat,
                //                    lon: lon
                //                )
                
                self.navigationController.popToViewController(homeVC, animated: true)
            }
        }
        
        navigationController.pushViewController(locationVC, animated: true)
    }
}
