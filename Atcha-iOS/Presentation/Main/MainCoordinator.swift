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
    private var loginCoordinator: LoginCoordinator?
    private var homeRegisterCoordinator: HomeRegistrationCoordinator?
    
    private var mainViewModel: MainViewModel?
    
    var routeToOnboarding: (() -> Void)?
    var lockScreenConfrim: ((LegInfo?, String?) -> Void)?
    var routeHandler: ((MainRoute) -> Void)?
    var withdrawFinish: (() -> Void)?
    
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
        case .changeHome:
            let homeDI = diContainer.makeHomeRegisterDIContainer()
            let coordinator = HomeRegistrationCoordinator(navigationController: navigationController, diContainer: homeDI)
            
            self.homeRegisterCoordinator = coordinator // 강한 참조 유지
            coordinator.onFinish = { [weak self] in
                self?.homeRegisterCoordinator = nil // 여기서 해제
                self?.mainViewModel?.refreshCurrentMapCenterData()
            }
            coordinator.start()
            
        case .myPage:
            let myPageDI = diContainer.makeMyPageDIContainer()
            let myPageCoordinator = MyPageCoordinator(
                navigationController: navigationController,
                diContainer: myPageDI
            )
            self.myPageCoordinator = myPageCoordinator
            myPageCoordinator.signoutFinish = { [weak self] in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    self.mainViewModel?.isGuest = true
                    self.mainViewModel?.bottomType = .search
                    self.navigationController.popToRootViewController(animated: true)
                    
                    self.myPageCoordinator = nil
                }
            }
            myPageCoordinator.withdrawFinish = { [weak self] in
                DispatchQueue.main.async {
                    self?.withdrawFinish?()
                }
            }
            
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
            if navigationController.topViewController is DetailRouteViewController {
                print("이미 상세 경로 화면입니다. 중복 push를 방지합니다.")
                return
            }
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
                case .dismissLockScreen:
                    self?.navigationController.dismiss(animated: true)
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
                }
            }
        case .loginSheet:
            let loginDI = diContainer.makeLoginDIContainer()
            let loginCoordinator = LoginCoordinator(
                navigationController: self.navigationController,
                diContainer: loginDI
            )
            self.loginCoordinator = loginCoordinator
            
            loginCoordinator.onFinishWithExistUser = { [weak self] isExist in
                DispatchQueue.main.async {
                    self?.navigationController.dismiss(animated: true) {
                        guard let self = self else { return }
                        
                        let newGuestStatus = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.isGuest.rawValue) ?? false
                        self.mainViewModel?.isGuest = newGuestStatus
                        
                        if isExist {
                            //                            self.mainViewModel?.setupLocation()
                            self.mainViewModel?.refreshCurrentMapCenterData()
                        } else {
                            self.routeToOnboarding?()
                        }
                        
                        // 로그인 코디네이터 메모리 해제
                        self.loginCoordinator = nil
                    }
                }
            }
            
            loginCoordinator.onCancel = { [weak self] in
                DispatchQueue.main.async {
                    self?.loginCoordinator = nil
                }
            }
            
            loginCoordinator.start()
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
