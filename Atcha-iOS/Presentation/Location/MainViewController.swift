//
//  MainViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import UIKit
import Foundation
import CoreLocation
import TMapSDK
import VSMSDK
import SnapKit
import Combine

final class MainViewController: BaseViewController<MainViewModel>,
                                TMapWrapperDelegate{
    
    private let mapContainerView: TMapContainerView = TMapContainerView()
    private let lastTrainSearchView: LastTrainSearchBottomView = LastTrainSearchBottomView() // 알람 등록 전
    private let lastTrainDepartView: LastTrainDepartBottomView = LastTrainDepartBottomView() // 알람 등록 이후
    
    private let flagImageView: UIImageView = UIImageView()
    private let alarmTimeoutView: UIView = UIView()
    private let myPageButton: UIButton = UIButton()
    private let loactionButton: UIButton = UIButton()
    private let atchaImageView: CharacterJumpView = CharacterJumpView()
    private let ballonView: AtchaBallon = AtchaBallon()
    private let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.maximumFractionDigits = 0
        return f
    }()
    
    private var firstAddress: String?
    
    // MARK: - 최신 값 캐시(비동기 병합용)
    private var latestIsServiceRegion: Bool?
    private var latestFareString: String?
    
    // MARK: - 알람 등록 후 메시지 순환 인덱스
    private var postAlarmTapIndex = 0
    
    // MARK: - 방문 플래그 & 표시 규칙
    private var wasAlarmRegisteredOnLaunch = false
    
    // MARK: - 화면 하단 타입 / 설정 상태
    private var lastAppliedBottomType: MapBottomType?
    
    // MARK: - 네트워크/조회 상태
    private var lastFareRefreshTime: CFTimeInterval = 0
    private let fareRefreshInterval: CFTimeInterval = 60
    private var isFetchingFare = false
    
    // MARK: - 점프 애니메이션 스로틀링
    private var lastJumpTime: CFTimeInterval = 0
    private let minJumpInterval: CFTimeInterval = 1.0
    
    // MARK: - 상태 제어 변수 (추적/회전 관련)
    private var routeStartCoordinate: CLLocationCoordinate2D?
    private var shouldCenterToCurrentLocationOnce = false
    private var isFollowingUser = false
    
    private var lastCourseUpdateAt: CFTimeInterval = 0
    private let courseValidWindow: CFTimeInterval = 1.2
    
    var shouldShowWelcomeToast: Bool = false
    private var hasShownAlarmRegisteredToast = false
    private lazy var shouldShowTopLineInSearch: Bool = {
        let isRevisit = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.reVisit.rawValue) ?? false
        if !isRevisit {
            // 처음 방문 시 기기에는 '방문함'으로 저장해두되,
            // 현재 앱이 켜져있는 이 세션 동안은 계속 true(첫 방문 취급)를 반환하도록 함
            UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.reVisit.rawValue)
            return true
        }
        return false
    }()
    
    private var isFirstVisit: Bool = false
    private var isShowingToast = false
    private var balloonHideWorkItem: DispatchWorkItem?
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !UserDefaults.standard.bool(forKey: "IsAppFirstLaunchedEver") {
            self.isFirstVisit = true
            UserDefaults.standard.set(true, forKey: "IsAppFirstLaunchedEver")
        }
        
        wasAlarmRegisteredOnLaunch = UserDefaultsWrapper.shared.bool(
            forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue
        ) ?? false
        
        self.onNetworkReconnect = { [weak self] in
            self?.mapContainerView.reloadMapView()
        }
        
        viewModel.setLoading(true)
        
        setupUI()
        setupAutoLayout()
        mapContainerView.onUserInteraction = { [weak self] in
            self?.stopFollowingOnUserInteraction()
        }
        bindView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let isAlarmRegistered = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) ?? false
        let isAlarmFired = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue) ?? false
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if !isAlarmRegistered {
                // 1. 앱 진입 시 현위치 1번 찍기 (초기화)
                self.mapContainerView.beforeUserMarker()
                self.isFollowingUser = false
                self.viewModel.stopHeading()
                
                if let currentCoord = self.viewModel.selectedLocation ?? self.viewModel.currentLocation {
                    self.mapContainerView.setupCenter(location: currentCoord)
                    self.shouldCenterToCurrentLocationOnce = false
                } else {
                    self.shouldCenterToCurrentLocationOnce = true
                }
                
            } else if isAlarmRegistered && !isAlarmFired {
                // 2. 알람 등록 후 (다른 화면 갔다가 돌아왔을 때 출발지 기준으로 보여줌)
                self.mapContainerView.afterUserMarker()
                self.isFollowingUser = false
                self.viewModel.stopHeading()
                if let startCoord = self.routeStartCoordinate {
                    self.mapContainerView.setupZoomCenter(location: startCoord)
                }
                
            } else if isAlarmRegistered && isAlarmFired {
                // 3. 알람 울린 후 (현위치 추적 모드)
                self.mapContainerView.afterUserMarker()
                self.isFollowingUser = true
                self.viewModel.startHeading()
                
                if let currentCoord = self.viewModel.currentLocation {
                    self.mapContainerView.setupCenter(location: currentCoord)
                    self.shouldCenterToCurrentLocationOnce = false
                } else {
                    self.shouldCenterToCurrentLocationOnce = true
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldShowWelcomeToast {
            shouldShowWelcomeToast = false
            
            
            self.view.showToast(message: "집 주소가 등록되었어요")
            
            
            let status = CLLocationManager.authorizationStatus()
            if status != .authorizedAlways && status != .authorizedWhenInUse {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.ensureLocationPermissionOrShowToast()
                }
            }
            
            // 즉시 말풍선 업데이트 (1줄짜리로 자연스럽게 나타남)
            if self.viewModel.bottomType == .search || self.viewModel.bottomType == nil {
                self.showOrUpdatePersistentBalloon(
                    isFirstVisit: self.isFirstVisit,
                    isServiceRegion: self.latestIsServiceRegion ?? false,
                    fareStr: self.latestFareString
                )
            }
        }
        
        self.viewModel.refreshCurrentMapCenterData()
        
        let isGuest = UserDefaultsWrapper.shared.bool(
            forKey: UserDefaultsWrapper.Key.isGuest.rawValue
        ) ?? false
        
        if isGuest {
            amp_track(.main_view, properties: props(AmplitudeProperty.userStatus(.guest)))
        } else {
            amp_track(.main_view, properties: props(AmplitudeProperty.userStatus(.member)))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        shouldCenterToCurrentLocationOnce = false
        isFollowingUser = false
        
        view.subviews
            .compactMap { $0 as? AtchaToast }
            .forEach { $0.hideImmediately() }
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        view.addSubViews(
            mapContainerView,
            flagImageView,
            atchaImageView,
            lastTrainSearchView,
            loactionButton,
            lastTrainDepartView,
            ballonView,
            myPageButton
        )
        
        mapContainerView.delegate = self
        configureButton(myPageButton,
                        imageName: "mypage-filled",
                        action: #selector(didTapMyPageButton))
        configureButton(loactionButton,
                        imageName: "mylocation-filled",
                        action: #selector(didTapLocationButton))
        flagImageView.image = UIImage.settingLocationMark
        atchaImageView.isUserInteractionEnabled = true
        atchaImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleBallonTap)))
        
        ballonView.isHidden = true
        ballonView.alpha = 0
    }
    
    private func configureButton(_ button: UIButton, imageName: String, action: Selector) {
        button.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    deinit {
        activePermissionToast?.hideImmediately()
    }
}

// MARK: AutoLayout
extension MainViewController {
    private func setupAutoLayout() {
        flagImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(mapContainerView.snp.centerY).offset(-63)
            make.height.equalTo(63)
            make.width.equalTo(48)
        }
        lastTrainSearchView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        lastTrainDepartView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        loactionButton.snp.makeConstraints { make in
            make.bottom.equalTo(lastTrainSearchView.snp.top).inset(-16)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        ballonView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.bottom.equalTo(atchaImageView.snp.top)
        }
        atchaImageView.snp.makeConstraints { make in
            make.width.height.equalTo(74)
            make.leading.equalToSuperview().inset(8)
            make.bottom.equalTo(lastTrainSearchView.snp.top).inset(22)
        }
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(lastTrainSearchView.snp.top).inset(30)
        }
        
        myPageButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
    }
}

// MARK: - Bindings
extension MainViewController {
    private func bindView() {
        bindBottomViewActions()
        bindAddressUpdates()
        bindCurrentLocationUpdates()
        bindSelectedLocationUpdates()
        bindAddressDescriptionUpdates()
        bindLegPathUpdates()
        bindTaxiFareUpdates()
        bindServiceRegionUpdates()
        bindLockView()
        bindDeviceHeadingUpdates()
        bindPermissionAlert()
        bindAlarmFireStatus()
        observeArrival()
        observeAlarmTimeout()
    }
    
    private func bindPermissionAlert() {
        viewModel.$showLocationDeniedAlert
            .filter { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.presentLocationDeniedAlert()
                self?.viewModel.showLocationDeniedAlert = false
            }
            .store(in: &cancellables)
    }
    
    // MARK: - bind Lock View
    private func bindLockView() {
        viewModel.$showLockView
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                guard let self, show else { return }
                self.viewModel.handleRoute(route: .lockScreen(info: nil, address: nil))
                self.viewModel.showLockView = false
            }
            .store(in: &cancellables)
    }
    
    // MARK: - View Actions
    private func bindBottomViewActions() {
        lastTrainSearchView.actionPublisher
            .sink { [weak self] in self?.handleSearchViewAction($0) }
            .store(in: &cancellables)
        
        lastTrainDepartView.actionPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.handleTrainDepartAction($0) }
            .store(in: &cancellables)
    }
    
    private func bindAlarmFireStatus() {
        UserDefaults.standard.publisher(for: \.departureAlarmDidFire)
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isFired in
                guard let self = self else { return }
                
                self.lastTrainDepartView.updateUIForAlarmStatus(isFired: isFired)
                
                if isFired {
                    self.isFollowingUser = true
                    self.viewModel.startHeading()
                    self.mapContainerView.afterUserMarker()
                    
                    if let currentCoord = self.viewModel.currentLocation {
                        self.mapContainerView.setupCenter(location: currentCoord)
                    }
                } else {
                    self.isFollowingUser = false
                    self.viewModel.stopHeading()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleSearchViewAction(_ action: LastTrainSearchBottomView.Action) {
        switch action {
        case .homeChangeTapped:
            if viewModel.isGuest {
                presentLoginAlert()
                amp_track(.login_view, properties: props(AmplitudeProperty.entryPoint(.home_modify)))
            } else {
                viewModel.handleRoute(route: .changeHome)
            }
        case .currentTapped:
            if viewModel.isGuest {
                presentLoginAlert()
                amp_track(.login_view, properties: props(AmplitudeProperty.entryPoint(.departure)))
            } else {
                viewModel.handleRoute(route: .changeCourse(
                    location: Location(name: "", lat: 0.0, lon: 0.0, businessCategory: "", address: "", radius: "")))
            }
        case .searchTapped:
            if viewModel.isGuest {
                presentLoginAlert()
                amp_track(.login_view, properties: props(AmplitudeProperty.entryPoint(.course_search)))
            } else {
                guard let startCoord = mapContainerView.tMapWrapper.mapView.getCenter() else {
                    view.showToast(message: "현재 위치를 확인 중이에요. 잠시 후 다시 시도해 주세요.")
                    return
                }
                
                let wrapper = UserDefaultsWrapper.shared
                let endLatStr = wrapper.string(forKey: UserDefaultsWrapper.Key.homeLat.rawValue) ?? "37.554722"
                let endLonStr = wrapper.string(forKey: UserDefaultsWrapper.Key.homeLon.rawValue) ?? "126.970833"
                
                guard let endLat = Double(endLatStr), let endLon = Double(endLonStr) else {
                    view.showToast(message: "저장된 목적지 좌표가 잘못되었어요.")
                    return
                }
                let endCoord = CLLocationCoordinate2D(latitude: endLat, longitude: endLon)
                
                if ProximityManager.shared.isWithinThreshold(from: startCoord, to: endCoord) {
                    viewModel.handleRoute(route: .proximity)
                    return
                }
                
                viewModel.handleRoute(route: .courseSearch(
                    startLat: String(startCoord.latitude), startLon: String(startCoord.longitude), startAddress: ""
                ))
            }
        }
    }
    
    private func handleTrainDepartAction(_ action: LastTrainDepartBottomView.Action) {
        switch action {
        case .exitTapped:
            showAlarmExitPopup()
            
        case .detailRoadMapTapped:
            viewModel.handleRoute(route: .detailRoute(address: "",
                                                      infos: LegInfo(pathInfo: [], trafficInfo: [], busInfo: []),
                                                      context: .afterReigster)
            )
            
        case .locationTapped:
            showTransientBalloon(isFare: false, text: "위치를 변경하려면 알람을 종료해야 해요")
            amp_track(.course_click)
            
        case .reloadTapped:
            viewModel.refreshDepatrueTime()
            
        case .timeTapped:
            showSequentialBalloons()
            amp_track(.departure_time_click)
        }
    }
    
    private func showAlarmTimeoutPopup() {
        let popupVM = AtchaPopupViewModel(info: .alarmTimeout)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.confirmButton.addAction(UIAction { [weak self, weak popupVC] _ in
            guard let self else { return }
            popupVC?.dismiss(animated: false)
            AlarmManager.shared.alarmInit()
        }, for: .touchUpInside)
        
        popupVC.modalPresentationStyle = .overFullScreen
        present(popupVC, animated: false)
    }
    
    private func showAlarmExitPopup() {
        let popupVM = AtchaPopupViewModel(info: .alarm)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.cancelButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: false)
        }, for: .touchUpInside)
        
        popupVC.confirmButton.addAction(UIAction { [weak self, weak popupVC] _ in
            guard let self else { return }
            popupVC?.dismiss(animated: false)
            
            self.viewModel.alarmDelete()
            self.exitButtonTapped()
            
            amp_track(.alarm_force_stop)
        }, for: .touchUpInside)
        
        popupVC.modalPresentationStyle = .overFullScreen
        present(popupVC, animated: false)
    }
    
    private func exitButtonTapped() {
        // 가장 먼저 토스트 표시 상태로 변경 (이후 2.5초간 호출되는 모든 말풍선 로직 차단됨)
        isShowingToast = true
        
        AlarmManager.shared.stopAlarm()
        viewModel.requestPermissionAndStartTracking()
        viewModel.removeLegInfoAndAddress()
        viewModel.stopHeading()
        
        isFollowingUser = false
        shouldCenterToCurrentLocationOnce = true
        hasShownAlarmRegisteredToast = false
        
        viewModel.bottomType = .search
        routeStartCoordinate = nil
        
        ballonView.layer.removeAllAnimations()
        ballonView.isHidden = true
        ballonView.alpha = 0
        
        atchaImageView.stop()
        mapContainerView.clearMapView()
        mapContainerView.beforeUserMarker()
        
        if let currentCoord = viewModel.currentLocation {
            mapContainerView.setupCenter(location: currentCoord)
            viewModel.selectedLocation = currentCoord
            shouldCenterToCurrentLocationOnce = false
        } else {
            shouldCenterToCurrentLocationOnce = true
            viewModel.setupLocation()
        }
        
        UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue)
        
        // 토스트 띄우고 토스트 사라진 후 고정형 말풍선 띄우기 (재방문 상태)
        showToastAndThen(message: "알람이 종료되었어요", delay: 2.5) { [weak self] in
            guard let self = self else { return }
            self.showOrUpdatePersistentBalloon(
                isFirstVisit: false,
                isServiceRegion: self.latestIsServiceRegion ?? false,
                fareStr: self.latestFareString
            )
        }
    }
    
    // MARK: - ViewModel Bindings
    
    private func bindCurrentLocationUpdates() {
        viewModel.$currentLocation
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] coord in
                guard let self = self else { return }
                
                let isAlarmRegistered = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) ?? false
                self.mapContainerView.updateUserMarker(location: coord, isRegistered: isAlarmRegistered)
                
                if self.isFollowingUser {
                    self.mapContainerView.setupCenter(location: coord)
                } else if self.shouldCenterToCurrentLocationOnce {
                    self.mapContainerView.setupCenter(location: coord)
                    self.shouldCenterToCurrentLocationOnce = false
                }
            }
            .store(in: &cancellables)
    }
    
    private func bindSelectedLocationUpdates() {
        viewModel.$selectedLocation
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { _ in }
            .store(in: &cancellables)
    }
    
    private func bindDeviceHeadingUpdates() {
        viewModel.$deviceHeading
            .compactMap { $0 }
            .removeDuplicates(by: { abs($0 - $1) < 2 })
            .receive(on: RunLoop.main)
            .sink { [weak self] heading in
                guard let self else { return }
                guard self.isFollowingUser else { return }
                
                self.mapContainerView.setHeading(heading)
            }
            .store(in: &cancellables)
    }
    
    private func bindAddressUpdates() {
        viewModel.$address
            .compactMap { $0 }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] (addr: String) in
                guard let self = self else { return }
                self.updateAddress(addr)
            }
            .store(in: &cancellables)
    }
    
    private func updateAddress(_ address: String) {
        if firstAddress == nil {
            firstAddress = address
        }
        
        let title = (address == firstAddress) ? "현위치: \(address)" : address
        lastTrainSearchView.setupCurrentLocationTitle(title)
    }
    
    private func bindAddressDescriptionUpdates() {
        viewModel.$addressDesc
            .receive(on: RunLoop.main)
            .sink { [weak self] desc in
                self?.lastTrainDepartView.setupLoaction(location: desc)
            }
            .store(in: &cancellables)
    }
    
    private func bindLegPathUpdates() {
        viewModel.$legInfo
            .receive(on: DispatchQueue.main)
            .combineLatest(viewModel.$bottomType)
            .sink { [weak self] info, bottomType in
                self?.commonAlarmSetupView()
                self?.addRouteLine(pathInfos: info?.pathInfo ?? [])
                
                switch bottomType {
                case .departure:
                    self?.shouldCenterToCurrentLocationOnce = false
                    self?.lastTrainDepartView.setupLegInfo(info: info)
                default: do {}
                }
                
                self?.setupBottomType(bottomType)
            }
            .store(in: &cancellables)
        
        viewModel.$bottomType
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] type in
                self?.setupBottomType(type)
            }
            .store(in: &cancellables)
        
        viewModel.$departureTime
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                self?.lastTrainDepartView.refreshDepartureTime(departureStr: time)
            }
            .store(in: &cancellables)
    }
    
    private func commonAlarmSetupView() {
        updateAtchaImageConstraint(relativeTo: lastTrainDepartView)
    }
    
    private func setupBottomType(_ type: MapBottomType?) {
        guard let type = type else { return }
        
        flagImageView.isHidden = true
        lastTrainSearchView.isHidden = true
        lastTrainDepartView.isHidden = true
        
        switch type {
        case .departure:
            self.shouldShowTopLineInSearch = false
            lastTrainDepartView.isHidden = false
            viewModel.startAlarmTimer()
            mapContainerView.afterUserMarker()
            
            ballonView.layer.removeAllAnimations()
            ballonView.isHidden = true
            ballonView.alpha = 0
            atchaImageView.stop()
            
            // 알람 등록 직후 토스트 + 순차 말풍선
            if !wasAlarmRegisteredOnLaunch && !hasShownAlarmRegisteredToast {
                hasShownAlarmRegisteredToast = true
                showToastAndThen(message: "알람이 등록되었습니다.", delay: 2.5) { [weak self] in
                    self?.showSequentialBalloons()
                }
            } else if wasAlarmRegisteredOnLaunch {
                showSequentialBalloons()
            }
            
        case .search:
            viewModel.stopFinishAlarmTimer()
            lastTrainSearchView.isHidden = false
            flagImageView.isHidden = false
            
            ballonView.layer.removeAllAnimations()
            ballonView.isHidden = true
            ballonView.alpha = 0
            atchaImageView.stop()
            
            mapContainerView.clearMapView()
            mapContainerView.beforeUserMarker()
            updateAtchaImageConstraint(relativeTo: lastTrainSearchView)
            
            let isService = self.latestIsServiceRegion ?? false
            
            // 여기도 동일하게 로딩중 무시 조건 적용
            if !isService || self.viewModel.isGuest || self.latestFareString != nil {
                showOrUpdatePersistentBalloon(
                    isFirstVisit: self.isFirstVisit,
                    isServiceRegion: isService,
                    fareStr: self.latestFareString
                )
            }
            
        case .detail:
            lastTrainDepartView.isHidden = false
            
        default: break
        }
        
        lastAppliedBottomType = type
    }
    
    private func bindTaxiFareUpdates() {
        Publishers.CombineLatest(viewModel.$taxiFare, viewModel.$isGuest)
            .receive(on: RunLoop.main)
            .sink { [weak self] fare, isGuest in
                guard let self = self else { return }
                
                if let fare = fare {
                    let fareInt = Int(fare)
                    self.latestFareString = self.decimalFormatter.string(from: NSNumber(value: fareInt)) ?? "\(fareInt)"
                } else {
                    self.latestFareString = nil
                }
                
                // 검색 모드일 때는 즉시 말풍선 글자 업데이트
                if self.viewModel.bottomType == .search {
                    let isService = self.latestIsServiceRegion ?? false
                    
                    // 핵심: 회원이면서 서비스 지역인데 아직 택시비가 없으면(로딩중) 업데이트 생략!
                    if !isService || isGuest || self.latestFareString != nil {
                        self.showOrUpdatePersistentBalloon(
                            isFirstVisit: self.isFirstVisit,
                            isServiceRegion: isService,
                            fareStr: self.latestFareString
                        )
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func bindServiceRegionUpdates() {
        viewModel.$isServiceRegion
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] ok in
                guard let self = self else { return }
                self.latestIsServiceRegion = ok
                
                switch ok {
                case .some(true):
                    self.lastTrainSearchView.updateSearchEnabled(true)
                case .some(false):
                    self.latestFareString = nil
                    self.viewModel.taxiFare = nil
                    self.lastTrainSearchView.updateSearchEnabled(false)
                case .none:
                    self.lastTrainSearchView.updateSearchEnabled(false)
                }
                
                // 검색 모드일 때는 즉시 말풍선 글자 업데이트
                if ok != nil && self.viewModel.bottomType == .search {
                    let isService = ok ?? false
                    
                    // 핵심: 회원이면서 서비스 지역인데 아직 택시비가 없으면(로딩중) 업데이트 생략!
                    if !isService || self.viewModel.isGuest || self.latestFareString != nil {
                        self.showOrUpdatePersistentBalloon(
                            isFirstVisit: self.isFirstVisit,
                            isServiceRegion: isService,
                            fareStr: self.latestFareString
                        )
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Constraint Helper
    private func updateAtchaImageConstraint(relativeTo view: UIView) {
        loactionButton.snp.remakeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
            make.bottom.equalTo(view.snp.top).inset(-16)
        }
        
        atchaImageView.snp.remakeConstraints { make in
            make.width.height.equalTo(74)
            make.leading.equalToSuperview()
            make.bottom.equalTo(view.snp.top).inset(26)
        }
    }
}

// MARK: Add Line
extension MainViewController {
    private func addRouteLine(pathInfos: [LegPathInfo]) {
        mapContainerView.clearMapView()
        var shapeStrings: [String] = []
        var colors: [UIColor] = []
        var images: [UIImage] = []
        var allCoordinates: [CLLocationCoordinate2D] = []
        
        pathInfos.forEach { info in
            switch info.mode {
            case .bus, .subway:
                if let shape = info.passShape, !shape.isEmpty {
                    shapeStrings.append(shape)
                    colors.append(info.mode?.getColor(for: info.type ?? "") ?? .magenta)
                    if let icon = info.mode?.getBorderIcon(for: info.type ?? "") {
                        images.append(icon)
                    }
                    allCoordinates.append(contentsOf: convertShapeToCoords(shape))
                }
            case .walk:
                if let steps = info.step, !steps.isEmpty {
                    let walkShapes = steps.compactMap { $0.linestring }.filter { !$0.isEmpty }
                    let merged = walkShapes.joined(separator: " ")
                    if !merged.isEmpty {
                        shapeStrings.append(merged)
                        colors.append(.gray200)
                        images.append(UIImage.routeCircleLineWalk)
                        allCoordinates.append(contentsOf: convertShapeToCoords(merged))
                    }
                } else if let shape = info.passShape, !shape.isEmpty {
                    shapeStrings.append(shape)
                    colors.append(.gray200)
                    images.append(UIImage.routeCircleLineWalk)
                    allCoordinates.append(contentsOf: convertShapeToCoords(shape))
                }
                
            default:
                break
            }
        }
        
        for (index, (shape, color, image)) in zip3(shapeStrings, colors, images).enumerated() {
            let isFirst = index == 0
            let isLast = index == shapeStrings.count - 1
            mapContainerView.addTrafficLine(passShape: shape, color: color, markerImage: image, isFirst: isFirst, isLast: isLast)
        }
        
        if let startCoordinate = allCoordinates.first {
            self.routeStartCoordinate = startCoordinate
            
            let isAlarmRegistered = UserDefaultsWrapper.shared.bool(
                forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue
            ) ?? false
            
            let isAlarmFired = UserDefaultsWrapper.shared.bool(
                forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue
            ) ?? false
            
            if isAlarmRegistered && !isAlarmFired {
                mapContainerView.setupZoomCenter(location: startCoordinate)
            }
        }
    }
    
    private func convertShapeToCoords(_ shape: String) -> [CLLocationCoordinate2D] {
        shape.split(separator: " ").compactMap { pair in
            let parts = pair.split(separator: ",")
            guard parts.count == 2,
                  let lon = Double(parts[0]),
                  let lat = Double(parts[1]) else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
    
    private func zip3<A, B, C>(_ a: [A], _ b: [B], _ c: [C]) -> [(A, B, C)] {
        let count = min(a.count, b.count, c.count)
        return (0..<count).map { (a[$0], b[$0], c[$0]) }
    }
}

extension MainViewController {
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.hideLoading()
            self.viewModel.setupLocation()
            
            let wrapper = UserDefaultsWrapper.shared
            if let legInfo: LegInfo = wrapper.object(forKey: UserDefaultsWrapper.Key.legInfo.rawValue, of: LegInfo.self),
               let address: String = wrapper.string(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue) {
                self.viewModel.drawRoute(address: address, info: legInfo)
                return
            }
            
            let isAlarmRegistered = wrapper.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) ?? false
            if !isAlarmRegistered {
                self.mapContainerView.beforeUserMarker()
            } else {
                self.mapContainerView.afterUserMarker()
            }
        }
    }
    
    @objc private func didTapMyPageButton() {
        if viewModel.isGuest {
            presentLoginAlert()
            amp_track(.login_view, properties: props(AmplitudeProperty.entryPoint(.mypage)))
        } else {
            viewModel.handleRoute(route: .myPage)
            amp_track(.mypage_click)
        }
    }
    
    @objc private func didTapLocationButton() {
        guard ensureLocationPermissionOrShowToast() else { return }
        
        viewModel.forceLocationSnap()
        
        isFollowingUser = true
        viewModel.startHeading()
        
        if let coord = viewModel.currentLocation {
            mapContainerView.setupCenter(location: coord)
            viewModel.selectedLocation = coord
        } else {
            shouldCenterToCurrentLocationOnce = true
            viewModel.setupLocation()
        }
        
        amp_track(.current_location_click)
    }
    
    private func safeStartJump() {
        let now = CACurrentMediaTime()
        guard now - lastJumpTime > minJumpInterval else { return }
        lastJumpTime = now
        atchaImageView.stop()
        atchaImageView.start()
    }
    
    @objc private func handleBallonTap() {
        // 알람 등록 후(departure 상태)일 때만 반응
        guard viewModel.bottomType == .departure else { return }
        
        amp_track(.character_click)
        
        let cycle = postAlarmTapIndex % 3
        
        // 추가: 현재 알람이 울린 상태인지 확인
        let isAlarmFired = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue) ?? false
        
        if cycle == 0 {
            // 요금 정보 표시 (동적 로딩)
            let now = CACurrentMediaTime()
            if (now - lastFareRefreshTime) > fareRefreshInterval && !isFetchingFare {
                isFetchingFare = true
                Task {
                    defer { Task { @MainActor in self.isFetchingFare = false } }
                    do {
                        let fare = try await viewModel.fetchFareForRegisteredStart()
                        let fareInt = Int(fare)
                        let fareStr = self.decimalFormatter.string(from: NSNumber(value: fareInt)) ?? "\(fareInt)"
                        await MainActor.run {
                            self.latestFareString = fareStr
                            self.lastFareRefreshTime = CACurrentMediaTime()
                            let displayFare = self.viewModel.isGuest ? "???원" : "\(fareStr)원"
                            self.showTransientBalloon(isFare: true, text: displayFare)
                            self.postAlarmTapIndex += 1
                        }
                    } catch {
                        await MainActor.run {
                            self.showTransientBalloon(isFare: false, text: "택시비 조회에 실패했어요")
                            self.postAlarmTapIndex += 1
                        }
                    }
                }
            } else {
                let fareStr = latestFareString ?? "???"
                let displayFare = viewModel.isGuest ? "???원" : "\(fareStr)원"
                showTransientBalloon(isFare: true, text: displayFare)
                self.postAlarmTapIndex += 1
            }
            
        } else if cycle == 1 {
            // 수정: 알람이 울렸다면 이 메시지를 건너뛰고 다음 메시지를 띄움
            if isAlarmFired {
                showTransientBalloon(isFare: false, text: "교통 상황에 따라 시간이 달라질 수 있어요")
                // cycle 1을 건너뛰었으므로 다음 탭이 cycle 0(택시비)으로 돌아가도록 index를 2 올려줌
                postAlarmTapIndex += 2
            } else {
                showTransientBalloon(isFare: false, text: "시간에 맞춰 알림을 드릴게요")
                postAlarmTapIndex += 1
            }
            
        } else {
            showTransientBalloon(isFare: false, text: "교통 상황에 따라 시간이 달라질 수 있어요")
            postAlarmTapIndex += 1
        }
    }
}

// MARK: - Map Delegate & Gesture
extension MainViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {
        viewModel.selectedLocation = coordinate
    }
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {
        stopFollowingOnUserInteraction()
        viewModel.selectedLocation = coordinate
    }
}

extension MainViewController: UIGestureRecognizerDelegate {
    private func installMapUserGestureDetector() {
        let targetView = mapContainerView.gestureTargetView
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(userDidManipulateMap))
        pan.cancelsTouchesInView = false
        pan.delegate = self
        targetView.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(userDidManipulateMap))
        pinch.cancelsTouchesInView = false
        pinch.delegate = self
        targetView.addGestureRecognizer(pinch)
        
        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(userDidManipulateMap))
        rotate.cancelsTouchesInView = false
        rotate.delegate = self
        targetView.addGestureRecognizer(rotate)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc private func userDidManipulateMap(_ g: UIGestureRecognizer) {
        if g.state == .began || g.state == .changed {
            stopFollowingOnUserInteraction()
        }
    }
    
    private func stopFollowingOnUserInteraction() {
        if isFollowingUser {
            isFollowingUser = false
            shouldCenterToCurrentLocationOnce = false
            viewModel.stopHeading()
        }
    }
}

extension MainViewController {
    private func presentLoginAlert() {
        self.viewModel.handleRoute(route: .loginSheet)
    }
}

extension MainViewController {
    private func presentLocationDeniedAlert() {
        let alert = UIAlertController(
            title: nil,
            message: "위치 권한을 허용하지 않으면\n현위치의 막차를 확인할 수 없어요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "설정하기", style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        present(alert, animated: true)
    }
}

// MARK: - 도착 자동 종료 처리
extension MainViewController {
    private func observeArrival() {
        NotificationCenter.default.publisher(for: NSNotification.Name("userArrivedHome"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.navigationController?.popToRootViewController(animated: true)
                self.viewModel.alarmDelete()
                self.exitButtonTapped()
                
                amp_track(.alarm_arrive_stop)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.showArrivalPopup()
                }
            }
            .store(in: &cancellables)
    }
    
    private func showArrivalPopup() {
        if presentedViewController is AtchaPopupViewController { return }
        
        let popupVM = AtchaPopupViewModel(info: .arrive)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.modalPresentationStyle = .overFullScreen
        popupVC.modalTransitionStyle = .crossDissolve
        
        popupVC.confirmButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: false)
            HomeArrivalManager.shared.reset()
        }, for: .touchUpInside)
        
        self.present(popupVC, animated: false)
    }
    
    private func observeAlarmTimeout() {
        NotificationCenter.default.publisher(for: NSNotification.Name("alarmDidTimeout"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.navigationController?.popToRootViewController(animated: true)
                self.viewModel.alarmDelete()
                self.exitButtonTapped()
                
                amp_track(.alarm_timeout_stop)
                
                if let coord = self.viewModel.currentLocation {
                    self.mapContainerView.setupCenter(location: coord)
                    self.viewModel.selectedLocation = coord
                } else {
                    self.viewModel.setupLocation()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showAlarmTimeoutPopup()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - 말풍선 제어 코어 로직
extension MainViewController {
    
    // 토스트를 띄우고 정해진 시간 뒤에 클로저를 실행하는 헬퍼 함수
    private func showToastAndThen(message: String, delay: TimeInterval = 2.5, completion: @escaping () -> Void) {
        isShowingToast = true // 켜기
        ballonView.layer.removeAllAnimations()
        ballonView.isHidden = true
        ballonView.alpha = 0
        
        self.view.showToast(message: message)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.isShowingToast = false // 끄기
            completion()
        }
    }
    
    // 1 & 2. 알람 등록 전 (고정형) - 위치 이동시 글자만 바뀜
    private func showOrUpdatePersistentBalloon(isFirstVisit: Bool, isServiceRegion: Bool, fareStr: String?) {
        guard !isShowingToast else { return } // 토스트 떠있으면 무조건 무시!
        
        let displayFare = viewModel.isGuest ? "???원" : "\(fareStr ?? "???")원"
        let topText = "지도를 움직여 출발지를 설정해요"
        
        // 말풍선 내용 세팅
        if isServiceRegion {
            ballonView.separationTitle(grayMessage: "여기서 막차 놓치면 택시비 ", whiteMessage: "약 \(displayFare)", showTopLine: isFirstVisit)
        } else {
            ballonView.setupTitle(topMessage: isFirstVisit ? topText : nil, bottomMessage: "서울, 경기, 인천 내에서만 사용할 수 있어요")
        }
        
        // 이미 떠 있으면 텍스트만 업데이트, 아니면 새로 등장
        if ballonView.isHidden || ballonView.alpha == 0 {
            safeStartJump() // 무조건 점프!
            ballonView.isHidden = false
            ballonView.alpha = 1
            
            // 처음 뜰 때는 서서히 애니메이션 적용 (두 줄이면 0.8초 딜레이 뒤 아래쪽 등장)
            let delay: TimeInterval = isFirstVisit ? 0.8 : 0.0
            ballonView.animateStaggered(secondaryDelay: delay, fade: 0.3)
        } else {
            // 이미 떠있는 상태면 위치 이동으로 인한 글자 업데이트이므로 즉시 바꿈
            ballonView.revealImmediately()
        }
    }
    
    // 3. 순차형 (알람 등록 직후 & timeTapped)
    private func showSequentialBalloons() {
        guard !isShowingToast else { return } // 토스트 떠있으면 무조건 무시!
        
        balloonHideWorkItem?.cancel()
        
        safeStartJump()
        ballonView.layer.removeAllAnimations()
        ballonView.isHidden = false
        ballonView.alpha = 1
        
        ballonView.setupTitle(topMessage: "이때 자리에서 출발하면 돼요", bottomMessage: "교통 상황에 따라 시간이 달라질 수 있어요")
        
        // 1. 위가 먼저 나타나고 '1.0초' 뒤 아래가 나타남
        ballonView.animateStaggered(secondaryDelay: 1.0, fade: 0.3)
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.ballonView.animateHideStaggered(secondaryDelay: 1.0, fade: 0.3)
        }
        
        balloonHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
    
    // 4. 휘발형 (캐릭터 탭, locationTapped)
    private func showTransientBalloon(isFare: Bool, text: String) {
        guard !isShowingToast else { return } // 토스트 떠있으면 무조건 무시!
        balloonHideWorkItem?.cancel()
        
        safeStartJump()
        ballonView.layer.removeAllAnimations()
        ballonView.isHidden = false
        ballonView.alpha = 1
        
        if isFare {
            ballonView.separationTitle(grayMessage: "막차 놓치면 택시비 ", whiteMessage: "약 \(text)", showTopLine: false)
        } else {
            ballonView.setupTitle(topMessage: nil, bottomMessage: text)
        }
        
        // 한 줄만 즉시/스태거로 띄움
        ballonView.animateStaggered(secondaryDelay: 0, fade: 0.25)
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.ballonView.animateHideStaggered(secondaryDelay: 0, fade: 0.25)
        }
        
        balloonHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
}
