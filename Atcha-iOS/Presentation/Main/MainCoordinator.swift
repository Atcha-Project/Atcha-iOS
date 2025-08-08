//
//  MainCoordinator.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/22/25.
//

import UIKit
import TMapSDK
import Foundation

final class MainCoordinator {
    private let navigationController: UINavigationController
    private let diContainer: MainDIContainer
    private var myPageCoordinator: MyPageCoordinator?
    
    private var mainViewModel: MainViewModel?
    
    var signoutFinish: (() -> Void)?
    var lockScreenConfrim: ((LegInfo?, String?) -> Void)?
    var routeHandler: ((MainRoute) -> Void)?
    
    init(navigationController: UINavigationController,
         diContainer: MainDIContainer) {
        self.navigationController = navigationController
        self.diContainer = diContainer
    }
    
    func start(info: LegInfo? = nil,
               address: String? = nil,
               bottomType: MapBottomType = .search) {
        let viewModel = diContainer.makeMainiewModel()
        self.mainViewModel = viewModel
        
        viewModel.bottomType = bottomType
        
        viewModel.routeHandler = { [weak self] route in
            guard let self else { return }
            handle(route: route)
        }
        viewModel.courseSearchResultHandler = { [weak self] address, info in
            guard let _ = self else { return }
            viewModel.bottomType = .departure
            viewModel.drawRoute(address: address, info: info)
//            viewModel.startAlarmTimer()
        }
        let viewController = diContainer.makeMainViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: false)
    }
    
    private func handle(route: MainRoute) {
        switch route {
        case .myPage:
            let myPageDI = diContainer.makeMyPageDIContainer()
            let myPageCoordinator = MyPageCoordinator(
                navigationController: navigationController,
                diContainer: myPageDI
            )
            self.myPageCoordinator = myPageCoordinator
            myPageCoordinator.signoutFinish = self.signoutFinish 
            myPageCoordinator.start()
        case let .courseSearch(startLat, startLon, startAddress):
            let courseDI = diContainer.makeCourseDIContainer()
            let vm = courseDI.makeCourseSearchViewModel(startLat: startLat,
                                                        startLon: startLon,
                                                        startAddress: startAddress)
            let vc = courseDI.makeCourseSearchViewController(viewModel: vm)
            vm.getAlarmTapped = { [weak self] address, infos in
                guard let self else { return }
                self.mainViewModel?.courseSearchResultHandler?(address, infos)
                navigationController.popViewController(animated: true)
            }
            vm.getDetailTapped = { [weak self] address, infos in
                guard let self else { return }
                handle(route: .detailRoute(address: address, infos: infos))
            }
            self.navigationController.pushViewController(vc, animated: true)
        case .changeCourse:
            let courseDI = diContainer.makeCourseDIContainer()
            let modifyVM = courseDI.makeCourseModifyViewModel()
            
            modifyVM.onLocationSelected = { [weak self] location in
                guard let self else { return }
                let settingVM = courseDI.makeCourseSettingViewModel(location: location)
                
                settingVM.onTapLocationButton = { [weak self] locationInfo, coordinate in
                    guard let self else { return }
                    self.navigationController.popViewController(animated: true)
                    
                    if let modifyVC = self.navigationController.viewControllers
                        .compactMap({ $0 as? CourseModifyViewController }).last {
                        modifyVC.didReceiveLocation(locationInfo: locationInfo, coordinate: coordinate)
                    }
                }
                
                let settingVC = courseDI.makeCourseSettingViewController(viewModel: settingVM)
                self.navigationController.pushViewController(settingVC, animated: true)
            }
            
            modifyVM.onLocationConfirmed = { [weak self] locationInfo, coordinate in
                guard let self else { return }
                let searchVM = courseDI.makeCourseSearchViewModel(
                    startLat: "\(coordinate.latitude)",
                    startLon: "\(coordinate.longitude)",
                    startAddress: locationInfo.name ?? "주소 없음"
                )
                
                searchVM.getAlarmTapped = { [weak self] address, infos in
                    guard let self else { return }
                    self.mainViewModel?.courseSearchResultHandler?(address, infos)
                    self.navigationController.popViewController(animated: true)
                }
                searchVM.getDetailTapped = { [weak self] address, infos in
                    guard let self else { return }
                    self.handle(route: .detailRoute(address: address, infos: infos))
                }
                
                let searchVC = courseDI.makeCourseSearchViewController(viewModel: searchVM)
                self.navigationController.pushViewController(searchVC, animated: true)
            }
            
            let modifyVC = CourseModifyViewController(viewModel: modifyVM)
            self.navigationController.pushViewController(modifyVC, animated: true)
            
        case .detailRoute(let address, let infos):
            let routeDI = diContainer.makeRouteDIContainer()
            let vm = routeDI.makeDetailRouteViewModel(address: address, infos: infos)
            let vc = routeDI.makeDetailRouteViewController(viewModel: vm)
            navigationController.pushViewController(vc, animated: false)
            
        case .lockScreen:
            let lockScreenDI = diContainer.makeLockScreenDIContainer()
            let vm = lockScreenDI.makeLockScreenViewModel()
            vm.routerHandler = { [weak self] router in
                switch router {
                case .lockScreen(let info, let address):
                    self?.lockScreenConfrim?(info, address)
                default: do {}
                }
            }
            let vc = lockScreenDI.makeLockScreenViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            navigationController.present(vc, animated: false)
        }
        
        routeHandler?(route)
    }
}
