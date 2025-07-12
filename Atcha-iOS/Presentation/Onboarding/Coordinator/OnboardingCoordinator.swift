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
    private let apiService: APIService
    private let locationHolder: LocationStateHolder
    
    private let homeDIConatiner: HomeRegisterDIContainer
    private let pushRegisterDIContainer: PushRegisterDIContainer
    
    var onFinish: ((Bool) -> Void)?
    var routeHandler: ((OnboardingRoute) -> Void)?
    
    init(apiService: APIService,
         navigationController: UINavigationController,
         locationHolder: LocationStateHolder,
         homeDIConatiner: HomeRegisterDIContainer,
         pushRegisterDIContainer: PushRegisterDIContainer) {
        self.apiService = apiService
        self.navigationController = navigationController
        self.homeDIConatiner = homeDIConatiner
        self.pushRegisterDIContainer = pushRegisterDIContainer
        self.locationHolder = locationHolder
    }
    
    func start() {
        showHomeRegister()
    }

    private func showHomeRegister() {
        let vm = homeDIConatiner.makeHomeRegisterViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = homeDIConatiner.makeHomeRegisterViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showHomeFind() {
        let vm = homeDIConatiner.makeHomeFindViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = homeDIConatiner.makeHomeFindViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showSearchAddress() {
        let vm = homeDIConatiner.makeHomeSearchViewModel()
        let vc = homeDIConatiner.makeHomeSearchViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func showPushRegister() {
        let vm = pushRegisterDIContainer.makePushRegisterViewModel()
        vm.routeHandler = { [weak self] route in self?.handle(route: route) }
        let vc = pushRegisterDIContainer.makePushRegisterViewController(viewModel: vm)
        navigationController.pushViewController(vc, animated: true)
    }
    
    private func handle(route: OnboardingRoute) {
        switch route {
        case .homeRegister:
            showHomeFind()
        case .searchAdress:
            showSearchAddress()
        case .pushRegister:
            showPushRegister()
        }
        
        routeHandler?(route)
    }
}



//private func showPushAlarm(with location: SelectedLocation) {
//    //        let viewModel = diContainer.makePushAlarmViewModel()
//    //        viewModel.selectedLocation = location
//    //
//    //        viewModel.onFinish = { [weak self] success in
//    //            self?.onFinish?(success)
//    //        }
//    //
//    //        let pushAlarmVC = PushAlarmViewController(viewModel: viewModel)
//    //        navigationController.pushViewController(pushAlarmVC, animated: true)
//}
//
//private func showSearchLocation() {
//    //        let viewModel = diContainer.makeSearchLocationViewModel()
//    //        let searchVC = SearchLocationViewController(viewModel: viewModel)
//
//    // RegisterLocation ViewController 이동
//    //        searchVC.onCurrentTapped = { [weak self] coordinate, placeName, address in
//    //            self?.showRegisterLocation(coordinate, placeName, address)
//    //        }
//    //
//    //        navigationController.pushViewController(searchVC, animated: true)
//}
//
////    private func showRegisterLocation(
////        _ coordinate: CLLocationCoordinate2D,
////        _ placeName: String,
////        _ address: String
////    ) {
////        let viewModel = diContainer.makeRegisterLocationViewModel()
////        let locationVC = RegisterLocationViewController(
////            viewModel: viewModel,
////            coordinate: coordinate,
////            placeName: placeName,
////            address: address
////        )
////
////        locationVC.onRegisterCompleted = { [weak self] name, address, lat, lon in
////            guard let self else { return }
////
////            if let homeVC = self.navigationController.viewControllers.first(where: { $0 is HomeRegisterViewController }) as? HomeRegisterViewController {
////
////                // ViewModel에 업데이트 메서드를 통해 반영 및 ViewController Pop
////                //                homeVC.viewModel.updateLocation(
////                //                    name: name,
////                //                    address: address,
////                //                    lat: lat,
////                //                    lon: lon
////                //                )
////
////                self.navigationController.popToViewController(homeVC, animated: true)
////            }
////        }
////
////        navigationController.pushViewController(locationVC, animated: true)
////    }
