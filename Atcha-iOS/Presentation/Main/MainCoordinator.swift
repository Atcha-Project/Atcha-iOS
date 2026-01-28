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
    private var busDetailCoordinator: BusDetailCoordinator?
    
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
                UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue)
                
                self.navigationController.popToMainViewControllerNoAnimation()
            }
            vm.getDetailTapped = { [weak self] address, infos in
                guard let self else { return }
                handle(route: .detailRoute(address: address, infos: infos, context: .beforeRegister))
            }
            
            vm.onTapRouteLabelStack = { [weak self] location in
                guard let self else { return }
                
                let modifyVM = courseDI.makeCourseModifyViewModel(location: location)
                let modifyVC = courseDI.makeCourseModifyViewController(viewModel: modifyVM)
                if let modifyVC = modifyVC as? CourseModifyViewController {
                    modifyVC.applyNewLocation(location)
                }
                
                modifyVM.onLocationSelected = { [weak self] location in
                    guard let self else { return }
                    let settingVM = courseDI.makeCourseSettingViewModel(location: location)
                    
                    settingVM.onTapLocationButton = { [weak self] locationInfo, coordinate in
                        guard let self else { return }
                        
                        let searchVM = courseDI.makeCourseSearchViewModel(
                            startLat: "\(coordinate.latitude)",
                            startLon: "\(coordinate.longitude)",
                            startAddress: locationInfo.name ?? "주소 없음"
                        )
                        
                        searchVM.getAlarmTapped = { [weak self] address, infos in
                            guard let self else { return }
                            self.mainViewModel?.courseSearchResultHandler?(address, infos)
                            UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue)
                            self.navigationController.popToMainViewControllerNoAnimation()
                        }
                        searchVM.getDetailTapped = { [weak self] address, infos in
                            guard let self else { return }
                            self.handle(route: .detailRoute(address: address, infos: infos, context: .beforeRegister))
                        }
                        
                        searchVM.onTapRouteLabelStack = { [weak self] location in
                            guard let self else { return }
                            guard let modifyVC = self.navigationController.viewControllers
                                .first(where: { $0 is CourseModifyViewController }) as? CourseModifyViewController else {
                                print("CourseModifyViewController not found in stack")
                                return
                            }
                            
                            modifyVC.applyNewLocation(location)
                            
                            UIView.performWithoutAnimation {
                                self.navigationController.popToViewController(modifyVC, animated: false)
                            }
                        }
                        
                        let searchVC = courseDI.makeCourseSearchViewController(viewModel: searchVM)
                        self.navigationController.pushViewController(searchVC, animated: false)
                    }
                    
                    let settingVC = courseDI.makeCourseSettingViewController(viewModel: settingVM)
                    self.navigationController.pushViewController(settingVC, animated: true)
                }
                
                UIView.performWithoutAnimation {
                    var vcs = self.navigationController.viewControllers
                    if let last = vcs.last, last is CourseSearchViewController {
                        vcs.removeLast()
                    }
                    vcs.append(modifyVC)
                    self.navigationController.setViewControllers(vcs, animated: false)
                }
            }
            
            self.navigationController.pushViewController(vc, animated: true)
        case let .changeCourse(location):
            let courseDI = diContainer.makeCourseDIContainer()
            let modifyVM = courseDI.makeCourseModifyViewModel(location: location)
            
            modifyVM.onLocationSelected = { [weak self] location in
                guard let self else { return }
                let settingVM = courseDI.makeCourseSettingViewModel(location: location)
                
                settingVM.onTapLocationButton = { [weak self] locationInfo, coordinate in
                    guard let self else { return }
                    
                    let searchVM = courseDI.makeCourseSearchViewModel(
                        startLat: "\(coordinate.latitude)",
                        startLon: "\(coordinate.longitude)",
                        startAddress: locationInfo.name ?? "주소 없음"
                    )
                    
                    searchVM.getAlarmTapped = { [weak self] address, infos in
                        guard let self else { return }
                        self.mainViewModel?.courseSearchResultHandler?(address, infos)
                        UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue)
                        self.navigationController.popToMainViewControllerNoAnimation()
                    }
                    searchVM.getDetailTapped = { [weak self] address, infos in
                        guard let self else { return }
                        self.handle(route: .detailRoute(address: address, infos: infos, context: .beforeRegister))
                    }
                    
                    searchVM.onTapRouteLabelStack = { [weak self] location in
                        guard let self else { return }
                        guard let modifyVC = self.navigationController.viewControllers
                            .first(where: { $0 is CourseModifyViewController }) as? CourseModifyViewController else {
                            print("CourseModifyViewController not found in stack")
                            return
                        }
                        
                        modifyVC.applyNewLocation(location)
                        
                        UIView.performWithoutAnimation {
                            self.navigationController.popToViewController(modifyVC, animated: false)
                        }
                    }
                    
                    let searchVC = courseDI.makeCourseSearchViewController(viewModel: searchVM)
                    self.navigationController.pushViewController(searchVC, animated: false)
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
                    UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue)
                    self.navigationController.popToMainViewControllerNoAnimation()
                }
                searchVM.getDetailTapped = { [weak self] address, infos in
                    guard let self else { return }
                    self.handle(route: .detailRoute(address: address, infos: infos, context: .beforeRegister))
                }
                
                let searchVC = courseDI.makeCourseSearchViewController(viewModel: searchVM)
                self.navigationController.pushViewController(searchVC, animated: true)
            }
            
            let modifyVC = CourseModifyViewController(viewModel: modifyVM)
            self.navigationController.pushViewController(modifyVC, animated: true)
            
        case .detailRoute(let address, let infos, let context):
            let routeDI = diContainer.makeRouteDIContainer()
            let vm = routeDI.makeDetailRouteViewModel(address: address, infos: infos, context: context)
            let vc = routeDI.makeDetailRouteViewController(viewModel: vm)
            
            vm.onBusDetail = { [weak self] busDetailInfo in
                guard let self else { return }
                let busDI = self.diContainer.makeBusInfoDIContainer()
                let busCoord = BusDetailCoordinator(
                    navigationController: self.navigationController,
                    diContainer: busDI
                )
                self.busDetailCoordinator = busCoord
                busCoord.start(busDetailInfo: busDetailInfo)
            }
            
            vm.getAlarmTapped = { [weak self] address, infos in
                guard let self else { return }
                mainViewModel?.courseSearchResultHandler?(address, infos)
                UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue)
                self.navigationController.popToMainViewControllerNoAnimation()
            }
            
            navigationController.pushViewController(vc, animated: false)
            
        case .lockScreen:
            let lockScreenDI = diContainer.makeLockScreenDIContainer()
            let vm = lockScreenDI.makeLockScreenViewModel()
            vm.routerHandler = { [weak self] router in
                self?.mainViewModel?.stopAlarmTimeoutTimer()
                
                switch router {
                case .lockScreen(let info, let address):
                    guard let info, let address else { return }
                    self?.navigationController.dismiss(animated: false) {
                        self?.handle(route: .detailRoute(address: address,
                                                         infos: info,
                                                         context: .afterReigster))
                    }
                case .courseSearch(let startLat, let startLon, let startAddress):
                    self?.navigationController.dismiss(animated: false) {
                        self?.handle(route: .courseSearch(startLat: startLat,
                                                          startLon: startLon,
                                                          startAddress: startAddress))
                    }
                default: do {}
                }
            }
            let vc = lockScreenDI.makeLockScreenViewController(viewModel: vm)
            vc.modalPresentationStyle = .overFullScreen
            navigationController.present(vc, animated: false)
        case .proximity:
            let proximityDI = diContainer.makeProximityDIContainer()
            let vm = proximityDI.makeProximityViewModel()
            let vc = proximityDI.makeProximityViewController(viewModel: vm)
            
            vc.modalPresentationStyle = .overFullScreen
            navigationController.present(vc, animated: false)
            
        case .dismissLockScreen:
            dismissPresentedIfNeeded {
                    DispatchQueue.global(qos: .utility).async {
                        self.mainViewModel?.showLockView = false
                        self.mainViewModel?.showAlarmStopPopUpView = true
                        
                        AlarmManager.shared.sendBackgroundPush(
                            title: "출발 알람이 자동 종료되었어요",
                            body: "클릭해서 경로 재탐색하기"
                        )
                        
                    }
                }
        }
        
        routeHandler?(route)
    }
    
    private func dismissPresentedIfNeeded(completion: (() -> Void)? = nil) {
        var top = navigationController.topViewController
        while let presented = top?.presentedViewController {
            top = presented
        }

        if top !== navigationController.topViewController {
            top?.dismiss(animated: false, completion: completion)
        } else {
            completion?()
        }
    }
}

extension UINavigationController {
    func popToMainViewControllerNoAnimation() {
        UIView.performWithoutAnimation {
            if let target = viewControllers.first(where: { $0 is MainViewController }) {
                popToViewController(target, animated: true)
            } else {
                popToRootViewController(animated: true)
            }
        }
    }
}
