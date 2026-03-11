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
    
    // MARK: - 말풍선 기본 설정
    private var pinnedPreBalloon: BalloonContent?
    private let balloonInitialDelayFirst: TimeInterval = 0.7   // 첫 노출 700ms
    private let balloonInitialDelaySecond: TimeInterval = 1.5  // (2개일 때) 두 번째 1500ms
    private let balloonHold: TimeInterval = 2.5                // 유지 2500ms
    private let balloonFade: TimeInterval = 0.25               // 페이드 250ms
    
    // MARK: - 말풍선 타입
    private enum BalloonContent: Equatable {
        case text(top: String?, bottom: String)
        case separation(gray: String, white: String) // (택시비: 회색+흰색 분리용)
    }
    
    private enum BalloonScope {
        case pre      // 알람 등록 전
        case next     // 알람 등록 후
    }
    
    // MARK: - 말풍선 큐 & 상태
    private var balloonQueue: [(content: BalloonContent, delay: TimeInterval, scope: BalloonScope)] = []
    private var isBalloonShowing = false
    private var hasShownInitialBalloon = false
    private var lastShownBalloon: BalloonContent?
    private var lastShownScope: BalloonScope?
    
    // MARK: - 최신 값 캐시(비동기 병합용)
    private var latestIsServiceRegion: Bool?
    private var latestFareString: String?
    
    // MARK: - 알람 등록 후 메시지(순환)
    private var postAlarmMessages: [BalloonContent] = []
    private var postAlarmIndex = 0
    
    // MARK: - 방문 플래그 & 표시 규칙
    private var isRevisit: Bool {
        UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.reVisit.rawValue) ?? false
    }
    private var showTopLineForPre: Bool { !isRevisit } // 신규 = true, 재방문 = false
    private var preSessionShowTopLine: Bool?
    private var deferPreBalloonOnce = false
    private var wasAlarmRegisteredOnLaunch = false
    
    // MARK: - 화면 하단 타입 / 설정 상태
    private var lastAppliedBottomType: MapBottomType?
    private var setupGen = 0
    private var firstBalloonWork: DispatchWorkItem?
    
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
    
    //    private var isGuest: Bool {
    //        return UserDefaultsWrapper.shared.bool(
    //            forKey: UserDefaultsWrapper.Key.isGuest.rawValue
    //        ) ?? false
    //    }
    
    var shouldShowWelcomeToast: Bool = false
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wasAlarmRegisteredOnLaunch = UserDefaultsWrapper.shared.bool(
            forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue
        ) ?? false
        
        self.onNetworkReconnect = { [weak self] in
            self?.mapContainerView.reloadMapView()
        }
        
        viewModel.setLoading(true)
        
        setupUI()
        setupAutoLayout()
        //        installMapUserGestureDetector()
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
                    self.shouldCenterToCurrentLocationOnce = false // 이미 이동했으니 대기 안 함
                } else {
                    self.shouldCenterToCurrentLocationOnce = true // 값이 없다면 위치를 찾을 때까지 대기
                }
                
            } else if isAlarmRegistered && !isAlarmFired {
                // 2. 알람 등록 후 (다른 화면 갔다가 돌아왔을 때 출발지 기준으로 보여줌)
                self.mapContainerView.afterUserMarker()
                self.isFollowingUser = false
                self.viewModel.stopHeading()
                if let startCoord = self.routeStartCoordinate {
                    self.mapContainerView.setupZoomCenter(location: startCoord)
                }
                
            }else if isAlarmRegistered && isAlarmFired {
                // 3. 알람 울린 후 (현위치 추적 모드)
                self.mapContainerView.afterUserMarker()
                self.isFollowingUser = true
                self.viewModel.startHeading()
                
                //수정된 부분: 화면 복귀 시 즉시 현위치로 카메라 이동
                if let currentCoord = self.viewModel.currentLocation {
                    // 즉시 중심으로 이동 (필요에 따라 setupZoomCenter를 사용해 줌 레벨까지 고정 가능)
                    self.mapContainerView.setupCenter(location: currentCoord)
                    self.shouldCenterToCurrentLocationOnce = false
                } else {
                    // 아직 좌표가 안 잡혔다면 위치가 업데이트될 때 이동하도록 플래그 세팅
                    self.shouldCenterToCurrentLocationOnce = true
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if shouldShowWelcomeToast {
            shouldShowWelcomeToast = false // 한 번 띄우고 바로 꺼줌
            
            // 첫 번째 토스트: 집 주소 등록 완료
            AtchaToast(message: "집 주소가 등록되었어요").show(in: self.view)
            
            // 두 번째 토스트: 위치 권한 체크
            let status = CLLocationManager.authorizationStatus()
            if status != .authorizedAlways && status != .authorizedWhenInUse {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.ensureLocationPermissionOrShowToast()
                }
            }
        }
        
        AmplitudeManager.shared.trackScreen(.main)
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
                self?.viewModel.showLocationDeniedAlert = false // 띄운 뒤 신호 초기화
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
        // UserDefaults의 변화를 실시간으로 구독합니다.
        UserDefaults.standard.publisher(for: \.departureAlarmDidFire)
            .removeDuplicates() // 같은 값이 연속으로 들어오는 것 방지
            .receive(on: RunLoop.main)
            .sink { [weak self] isFired in
                guard let self = self else { return }
                
                self.lastTrainDepartView.updateUIForAlarmStatus(isFired: isFired)
                
                if isFired {
                    // 1. 추적 플래그 ON
                    self.isFollowingUser = true
                    
                    // 2. 헤딩(회전) 시작
                    self.viewModel.startHeading()
                    
                    // 3. 유저 마커 스타일 변경 (알람 후 전용 마커가 있다면)
                    self.mapContainerView.afterUserMarker()
                    
                    // 4. 즉시 현재 위치로 지도 중심 이동
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
        case .currentTapped:
            if viewModel.isGuest {
                presentLoginAlert()
            } else {
                AmplitudeManager.shared.track(.origin_search_click)
                
                viewModel.handleRoute(route: .changeCourse(
                    location: Location(name: "", lat: 0.0, lon: 0.0, businessCategory: "", address: "", radius: "")))
            }
        case .searchTapped:
            if viewModel.isGuest {
                presentLoginAlert()
            } else {
                AmplitudeManager.shared.track(.course_search_click)
                
                guard let startCoord = viewModel.currentLocation else {
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
                    startLat: "", startLon: "", startAddress: ""
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
            self.showOrUpdateImmediateBalloon(
                .text(top: nil, bottom: "위치를 변경하려면 알람을 종료해야 해요")
            )
            AmplitudeManager.shared.track(.course_click)
        case .reloadTapped:
            viewModel.refreshDepatrueTime()
        case .timeTapped:
            self.showOrUpdateImmediateBalloon(
                .text(top: "이때 자리에서 출발하면 돼요", bottom: "교통 상황에 따라 시간이 달라질 수 있어요")
            )
            AmplitudeManager.shared.track(.origin_time_click)
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
        }, for: .touchUpInside)
        
        popupVC.modalPresentationStyle = .overFullScreen
        present(popupVC, animated: false)
    }
    
    private func exitButtonTapped() {
        AlarmManager.shared.stopAlarm()
        viewModel.requestPermissionAndStartTracking()
        viewModel.removeLegInfoAndAddress()
        viewModel.stopHeading()
        
        // 4. 알람 해제 시 1번(초기 상태)으로 돌아감
        isFollowingUser = false
        shouldCenterToCurrentLocationOnce = true
        
        // 이번 한 번은 프리 말풍선 자동 표시를 건너뛰도록 플래그 세팅
        deferPreBalloonOnce = true
        viewModel.bottomType = .search
        routeStartCoordinate = nil
        cancelBalloonQueueAndHide()
        atchaImageView.stop()
        mapContainerView.clearMapView()
        mapContainerView.beforeUserMarker()
        
        if let coord = viewModel.selectedLocation ?? viewModel.currentLocation {
            mapContainerView.setupCenter(location: coord)
        } else {
            viewModel.setupLocation()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            
            self.view.showToast(message: "알람이 종료되었어요")
            
            // 2초 뒤 수동으로 말풍선 표시 (이때 플래그 해제)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.deferPreBalloonOnce = false
                self.showInitialPreAlarmBalloons(force: true)
            }
            
            UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue)
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
                
                // 1. 파란색 내 위치 마커는 무조건 실시간 업데이트
                
                let isAlarmRegistered = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) ?? false
                let isAlarmFired = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue) ?? false
                self.mapContainerView.updateUserMarker(location: coord, isRegistered: isAlarmRegistered)
                // 2. 알람이 울린 상태면 무조건 강제로 센터 유지
                //                    if isAlarmRegistered && isAlarmFired {
                //                        self.isFollowingUser = true
                //                        self.viewModel.startHeading()
                //                        self.mapContainerView.setupCenter(location: coord)
                //                        return
                //                    }
                //
                //                    // 3. 앱 최초 진입이거나, 내가 현위치 버튼을 눌러서 '추적 모드'일 때만 카메라 중심 이동
                //                    if self.shouldCenterToCurrentLocationOnce || self.isFollowingUser {
                //                        self.mapContainerView.setupCenter(location: coord)
                //                        self.shouldCenterToCurrentLocationOnce = false
                //                    }
                if self.isFollowingUser {
                    self.mapContainerView.setupCenter(location: coord)
                } else if self.shouldCenterToCurrentLocationOnce {
                    // 앱 최초 진입 등 일회성 이동 로직
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
            .sink { _ in
                // 👉 뷰모델에서 알아서 주소를 검색하므로 뷰컨트롤러는 카메라를 건드리지 않음!
            }
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
            .compactMap { $0 }              // Optional<String> -> String
            .removeDuplicates()             // String 기준 중복 제거
            .receive(on: RunLoop.main)
            .sink { [weak self] (addr: String) in   // 타입 명시로 추론 고정
                guard let self = self else { return }
                self.updateAddress(addr)
                
                if self.hasShownInitialBalloon {
                    if self.latestIsServiceRegion == false {
                        self.showOrUpdatePreBalloon(
                            .text(
                                top: (self.preSessionShowTopLine ?? true) ? "지도를 움직여 출발지를 설정해요" : nil,
                                bottom: "서울, 경기, 인천 내에서만 사용할 수 있어요"
                            )
                        )
                    }
                } else {
                    self.showInitialPreAlarmBalloons(force: false)
                }
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
        let isSame = (lastAppliedBottomType == type)
        
        // 공통 초기 숨김
        flagImageView.isHidden = true
        lastTrainSearchView.isHidden = true
        lastTrainDepartView.isHidden = true
        
        switch type {
        case .departure:
            if !isSame { cancelBalloonQueueAndHide() }
            lastTrainDepartView.isHidden = false
            viewModel.startAlarmTimer()
            mapContainerView.afterUserMarker()
            
            setupGen &+= 1
            let gen = setupGen
            cancelBalloonQueueAndHide()
            atchaImageView.stop()
            self.setupPostAlarmMessages()
            
            // 두 번 연속 호출일 때만 0.7초, 아니면 0.2초 (기존 로직 유지)
            let delayBeforeScheduling: TimeInterval = isSame ? 0.7 : 0.2
            
            let popRegister = UserDefaultsWrapper.shared.bool(
                forKey: UserDefaultsWrapper.Key.popRegister.rawValue
            ) ?? false
            
            let popToastDelay: Double = popRegister ? 0.3 : 0.0
            let popBallonDelay: TimeInterval = popRegister ? 2.7 : 2.4
            
            // 앱을 켤 때부터 알람이 이미 등록되어 있었다면, post-delay(기존 2.0초)를 0으로
            let postRevealDelay: TimeInterval = wasAlarmRegisteredOnLaunch ? 0.0 : popBallonDelay
            
            self.scheduleFirstBalloon(gen: gen,
                                      delay: delayBeforeScheduling,
                                      postRevealDelay: postRevealDelay,
                                      popToastDelay: popToastDelay)
            
            preSessionShowTopLine = nil
            
        case .search:
            if !isSame { cancelBalloonQueueAndHide() }
            viewModel.stopFinishAlarmTimer()
            lastTrainSearchView.isHidden = false
            flagImageView.isHidden = false
            cancelBalloonQueueAndHide()
            atchaImageView.stop()
            
            mapContainerView.clearMapView()
            mapContainerView.beforeUserMarker()
            updateAtchaImageConstraint(relativeTo: lastTrainSearchView)
            
            hasShownInitialBalloon = false
            preSessionShowTopLine = nil
            
            // exit 흐름에서 지연 표시 예정이면 여기서는 자동 호출 안 함
            if !deferPreBalloonOnce {
                showInitialPreAlarmBalloons(force: true)
            }
            
        case .detail:
            lastTrainDepartView.isHidden = false
            
        default: break
        }
        
        lastAppliedBottomType = type
    }
    
    private func scheduleFirstBalloon(gen: Int,
                                      delay: TimeInterval,
                                      postRevealDelay: TimeInterval,
                                      popToastDelay: TimeInterval) {
        firstBalloonWork?.cancel()
        
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard gen == self.setupGen, self.viewModel.bottomType == .departure else { return }
            guard let first = self.postAlarmMessages.first else { return }
            
            if !wasAlarmRegisteredOnLaunch {
                DispatchQueue.main.asyncAfter(deadline: .now() + popToastDelay) {
                    self.view.showToast(message: "알람이 등록되었습니다.")
                    UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.popRegister.rawValue)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + postRevealDelay) {
                self.showOrUpdateImmediateBalloon(first)
            }
        }
        firstBalloonWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
    private func bindTaxiFareUpdates() {
        // taxiFare와 isGuest 중 하나라도 바뀌면 이 블록이 실행됩니다.
        Publishers.CombineLatest(viewModel.$taxiFare, viewModel.$isGuest)
            .receive(on: RunLoop.main)
            .sink { [weak self] fare, isGuest in
                guard let self = self, let fare = fare else { return }
                
                let fareInt = Int(fare)
                let fareStr = self.decimalFormatter.string(from: NSNumber(value: fareInt)) ?? "\(fareInt)"
                self.latestFareString = fareStr
                
                if self.isPreAlarmBalloonActive(), self.latestIsServiceRegion == true {
                    // 이제 파라미터로 들어오는 최신 isGuest 상태에 따라 ??? 혹은 금액이 결정됩니다.
                    let displayFare = isGuest ? "???원" : "\(fareStr)원"
                    let content: BalloonContent = .separation(
                        gray: "여기서 막차 놓치면 택시비 ", white: "약 \(displayFare)"
                    )
                    
                    if self.ballonView.isHidden {
                        self.showOrUpdatePreBalloon(content, showTopLine: self.preSessionShowTopLine ?? true)
                    } else {
                        self.updatePreBalloonContent(content, showTopLine: self.preSessionShowTopLine ?? true)
                    }
                }
                
                // 알람 등록 후 말풍선 큐 갱신
                if !self.postAlarmMessages.isEmpty {
                    let displayFare = isGuest ? "???원" : "\(fareStr)원"
                    self.postAlarmMessages[self.postAlarmMessages.count - 1] =
                        .separation(gray: "여기서 막차 놓치면 택시비 ", white: "약 \(displayFare)")
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
                let previous = self.latestIsServiceRegion
                self.latestIsServiceRegion = ok
                
                switch ok {
                case .some(true):
                    // 서비스 지역으로 들어옴!
                    self.lastTrainSearchView.updateSearchEnabled(true)
                    
                    if previous == nil {
                        self.showInitialPreAlarmBalloons(force: true)
                    } else if self.isPreAlarmBalloonActive() {
                        
                        // 수정: 게스트 모드면 요금(fare)이 없어도 바로 ???로 띄워줘야 함!
                        if viewModel.isGuest {
                            let content: BalloonContent = .separation(gray: "여기서 막차 놓치면 택시비 ", white: "약 ???원")
                            if self.ballonView.isHidden {
                                self.showOrUpdatePreBalloon(content, showTopLine: self.preSessionShowTopLine ?? true)
                            } else {
                                self.updatePreBalloonContent(content, showTopLine: self.preSessionShowTopLine ?? true)
                            }
                            
                        } else if let fare = self.latestFareString {
                            // 일반 회원이고 요금이 있을 때
                            let content: BalloonContent = .separation(gray: "여기서 막차 놓치면 택시비 ", white: "약 \(fare)원")
                            if self.ballonView.isHidden {
                                self.showOrUpdatePreBalloon(content, showTopLine: self.preSessionShowTopLine ?? true)
                            } else {
                                self.updatePreBalloonContent(content, showTopLine: self.preSessionShowTopLine ?? true)
                            }
                        }
                    }
                    
                case .some(false):
                    // 서비스 지역을 벗어남 (울산 등)
                    self.lastTrainSearchView.updateSearchEnabled(false)
                    if previous == nil {
                        self.showInitialPreAlarmBalloons(force: true)
                    } else if self.isPreAlarmBalloonActive() {
                        let content: BalloonContent =
                            .text(top: (self.preSessionShowTopLine ?? true) ? "지도를 움직여 출발지를 설정해요" : nil,
                                  bottom: "서울, 경기, 인천 내에서만 사용할 수 있어요")
                        if self.ballonView.isHidden {
                            self.showOrUpdatePreBalloon(content, showTopLine: self.preSessionShowTopLine ?? true)
                        } else {
                            self.updatePreBalloonContent(content, showTopLine: self.preSessionShowTopLine ?? true)
                        }
                    }
                    
                case .none:
                    self.lastTrainSearchView.updateSearchEnabled(false)
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
            
            // 지도가 완전히 로드된 이 시점에 setupLocation()을 호출해야 합니다!
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
        } else {
            viewModel.handleRoute(route: .myPage)
        }
    }
    
    @objc private func didTapLocationButton() {
        guard ensureLocationPermissionOrShowToast() else { return }
        
        isFollowingUser = true
        viewModel.startHeading()
        
        // 수정: 무조건 내 "진짜 위치(currentLocation)"로 지도를 이동시킴
        if let coord = viewModel.currentLocation {
            mapContainerView.setupCenter(location: coord)
            viewModel.selectedLocation = coord // 주소도 현위치로 다시 검색하게 덮어씀
        } else {
            shouldCenterToCurrentLocationOnce = true
            viewModel.setupLocation()
        }
    }
    
    private func safeStartJump() {
        let now = CACurrentMediaTime()
        guard now - lastJumpTime > minJumpInterval else { return }
        lastJumpTime = now
        atchaImageView.stop()
        atchaImageView.start()
    }
    
    @objc private func handleBallonTap() {
        atchaImageView.stop()
        atchaImageView.start()
        
        let scope = lastShownScope
        
        switch scope {
        case .pre:
            print("")
        case .next:
            AmplitudeManager.shared.track(.character_click)
            let now = CACurrentMediaTime()
            let shouldRefreshFare = (now - lastFareRefreshTime) > fareRefreshInterval
            
            if shouldRefreshFare && !isFetchingFare {
                isFetchingFare = true
                let vm = viewModel
                Task(priority: .userInitiated) {
                    defer { Task { @MainActor in self.isFetchingFare = false } }
                    do {
                        let fare = try await vm.fetchFareForRegisteredStart()
                        let fareInt = Int(fare)
                        let fareStr = self.decimalFormatter.string(from: NSNumber(value: fareInt)) ?? "\(fareInt)"
                        await MainActor.run {
                            self.latestFareString = fareStr
                            self.setupPostAlarmMessages()
                            // 이번 탭에선 요금 먼저 한 번 보여주고
                            self.showOrUpdateImmediateBalloon(
                                .separation(gray: "막차 놓치면 택시비 ", white: "약 \(fareStr)원")
                            )
                            // 다음 탭부터는 순환 문구가 나오도록 시작 인덱스 조정
                            self.postAlarmIndex = 1
                            self.lastFareRefreshTime = CACurrentMediaTime()
                        }
                    } catch {
                        await MainActor.run {
                            self.showOrUpdateImmediateBalloon(.text(top: nil, bottom: "택시비 조회에 실패했어요"))
                            // 실패 시에도 다음 탭은 순환 시작
                            self.postAlarmIndex = max(1, self.postAlarmIndex)
                        }
                    }
                }
                return  // 이번 탭은 요금만 보여주고 종료
            }
            
            // ===== 재조회 주기가 아닐 땐 순환 메시지 =====
            guard !postAlarmMessages.isEmpty else { return }
            if postAlarmIndex < 1 { postAlarmIndex = 1 } // 1..N-1 범위에서 순환
            let content = postAlarmMessages[postAlarmIndex]
            showOrUpdateImmediateBalloon(content)
            
            let cycleCount = postAlarmMessages.count - 1
            postAlarmIndex = 1 + ((postAlarmIndex - 1 + 1) % cycleCount)
            
        case .none:
            break
        }
    }
    
    // MARK: - Balloon (helpers + queue)
    
    private func applyBalloon(_ content: BalloonContent, showTopLine: Bool) {
        switch content {
        case .text(let top, let bottom):
            if let top = top {
                ballonView.setupTitle(topMessage: top, bottomMessage: bottom)
            } else {
                ballonView.setupTitle(bottomMessage: bottom)
            }
        case .separation(let gray, let white):
            ballonView.separationTitle(
                grayMessage: gray,
                whiteMessage: white,
                showTopLine: showTopLine
            )
        }
    }
    
    private func revealBalloon(animated: Bool) {
        ballonView.layer.removeAllAnimations()
        view.bringSubviewToFront(ballonView)
        
        if ballonView.isHidden {
            ballonView.alpha = 0
            ballonView.isHidden = false
            UIView.animate(withDuration: animated ? balloonFade : 0) {
                self.ballonView.alpha = 1
            }
        } else {
            ballonView.revealImmediately()
        }
        ballonView.animateStaggered(secondaryDelay: 0.8, fade: balloonFade)
    }
    
    private func autoHideBalloon(after delay: TimeInterval, completion: (() -> Void)? = nil) {
        guard !isPreAlarmBalloonActive() else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.ballonView.animateHideStaggered(
                secondaryDelay: 0.6,          // 필요하면 조절 (등장과 비슷하게 0.6~0.8 추천)
                fade: self.balloonFade,       // 기존 0.25 유지
                completion: { [weak self] in
                    guard let self else { return }
                    // 기존 상태 정리 로직 유지
                    self.ballonView.isHidden = true
                    completion?()
                }
            )
        }
    }
    
    // 내부 enqueue: 큐잉 + 드레인
    private func enqueueInternal(_ content: BalloonContent,
                                 delay: TimeInterval = 0,
                                 hold: TimeInterval? = nil,
                                 scope: BalloonScope) {
        if scope == .pre && !isPreAlarmBalloonActive() { return }
        balloonQueue.append((content, delay, scope))
        drainBalloonQueue(hold: hold ?? balloonHold)
    }
    
    // 등록 후 안내(큐잉)
    private func enqueueNextBalloon(_ content: BalloonContent,
                                    delay: TimeInterval = 0,
                                    hold: TimeInterval? = nil) {
        enqueueInternal(content, delay: delay, hold: hold, scope: .next)
    }
    
    // 큐 드레인
    private func drainBalloonQueue(hold: TimeInterval) {
        guard !isBalloonShowing, let next = balloonQueue.first else { return }
        isBalloonShowing = true
        balloonQueue.removeFirst()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + next.delay) { [weak self] in
            guard let self else { return }
            
            self.applyBalloon(next.content, showTopLine: false)
            self.revealBalloon(animated: true)
            
            self.lastShownBalloon = next.content
            self.lastShownScope = next.scope
            
            self.autoHideBalloon(after: hold) {
                self.isBalloonShowing = false
                self.drainBalloonQueue(hold: hold)
            }
        }
    }
    
    // 알람 등록 전: 즉시 고정(큐/오토숨김 없음)
    private func showOrUpdatePreBalloon(_ content: BalloonContent,
                                        delay: TimeInterval = 0,
                                        animated: Bool = true,
                                        showTopLine: Bool = true) {
        guard isPreAlarmBalloonActive() else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            
            // 같은 내용이면 스킵
            if self.pinnedPreBalloon == content, self.lastShownScope == .pre { return }
            
            // 이미 떠 있으면 내용만 교체하고 종료 (새로 생성/페이드인/스태거 X)
            if !self.ballonView.isHidden {
                self.updatePreBalloonContent(content, showTopLine: showTopLine)
                return
            }
            
            // 처음 띄울 때만 페이드인 + 스태거
            self.applyBalloon(content, showTopLine: showTopLine)
            self.revealBalloon(animated: animated)
            
            self.lastShownBalloon = content
            self.lastShownScope  = .pre
            self.pinnedPreBalloon = content
        }
    }
    
    // 초기 프리 말풍선
    private func showInitialPreAlarmBalloons(force: Bool = false) {
        guard let isService = latestIsServiceRegion else { return }
        guard isPreAlarmBalloonActive() else { return }
        
        if preSessionShowTopLine == nil {
            preSessionShowTopLine = !isRevisit
        }
        let showTopLine = preSessionShowTopLine ?? true
        let d1 = balloonInitialDelayFirst
        
        if isService {
            // 서비스 지역인데 아직 요금이 없으면 말풍선은 띄우지 않지만,
            // 재방문 처리(상단 라인 억제용)는 반드시 해두고 return
            guard let fare = latestFareString else {
                if !isRevisit {
                    UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.reVisit.rawValue)
                }
                
                // [추가 로직] 게스트일 경우 서버에서 요금을 안 주거나 늦게 줄 수 있으므로
                // 요금(fare)이 없어도 바로 ???로 띄워줍니다!
                if viewModel.isGuest {
                    showOrUpdatePreBalloon(
                        .separation(gray: "여기서 막차 놓치면 택시비 ", white: "약 ???원"),
                        delay: d1, animated: true, showTopLine: showTopLine
                    )
                    hasShownInitialBalloon = true
                }
                return
            }
            
            // 요금이 있고 서비스 지역일 때
            let displayFare = viewModel.isGuest ? "???원" : "\(fare)원"
            showOrUpdatePreBalloon(
                .separation(gray: "여기서 막차 놓치면 택시비 ", white: "약 \(displayFare)"),
                delay: d1, animated: true, showTopLine: showTopLine
            )
            
        } else {
            // 비서비스 지역은 기존 안내 문구 유지
            showOrUpdatePreBalloon(
                .text(top: showTopLine ? "지도를 움직여 출발지를 설정해요" : nil,
                      bottom: "서울, 경기, 인천 내에서만 사용할 수 있어요"),
                delay: d1
            )
        }
        
        // 여기까지 도달했을 때도 초기 방문이면 reVisit 저장
        if !isRevisit {
            UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.reVisit.rawValue)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.atchaImageView.stop()
            self?.atchaImageView.start()
        }
        hasShownInitialBalloon = true
    }
    
    // 즉시 표시(터치 등): 3초 뒤 오토숨김
    private func showOrUpdateImmediateBalloon(_ content: BalloonContent) {
        balloonQueue.removeAll()
        ballonView.layer.removeAllAnimations()
        self.safeStartJump()
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector: #selector(hideImmediateBalloon),
                                               object: nil)
        
        applyBalloon(content, showTopLine: false)
        revealBalloon(animated: true)
        
        perform(#selector(hideImmediateBalloon), with: nil, afterDelay: 3.0)
        
        lastShownBalloon = content
        lastShownScope = .next
        pinnedPreBalloon = content
        
        wasAlarmRegisteredOnLaunch = false
    }
    
    @objc private func hideImmediateBalloon() {
        autoHideBalloon(after: 0)
    }
    
    // 프리/포스트 여부
    private func isPreAlarmBalloonActive() -> Bool {
        return viewModel.bottomType == .search
    }
    
    private func updatePreBalloonContent(_ content: BalloonContent, showTopLine: Bool) {
        applyBalloon(content, showTopLine: showTopLine)
        ballonView.revealImmediately()          // 라벨만 보이게
        lastShownBalloon = content
        lastShownScope  = .pre
        pinnedPreBalloon = content
    }
    
    private func cancelBalloonQueueAndHide() {
        balloonQueue.removeAll()
        ballonView.layer.removeAllAnimations()
        ballonView.isHidden = true
        ballonView.alpha = 0
        isBalloonShowing = false
        pinnedPreBalloon = nil
        if lastShownScope == .pre { lastShownBalloon = nil }
    }
    
    private func setupPostAlarmMessages() {
        let fareStr = latestFareString ?? "12,000"
        postAlarmMessages = [
            .text(top: "이때 자리에서 출발하면 돼요", bottom: "교통 상황에 따라 시간이 달라질 수 있어요"),
            .text(top: nil, bottom: "시간에 맞춰 알림을 드릴게요"),
            .text(top: nil, bottom: "교통 상황에 따라 시간이 달라질 수 있어요"),
            .separation(gray: "막차 놓치면 택시비 ", white: "약 \(fareStr)원")
        ]
        postAlarmIndex = 1
    }
}

// MARK: - Map Delegate & Gesture
extension MainViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {
        // 위치가 업데이트 될 때마다 호출됨 (조작 방해를 막기 위해 비워둠)
        viewModel.selectedLocation = coordinate
    }
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {
        // 지도 단순 터치(탭) 시 추적 해제
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
        // 드래그, 줌 등의 제스처 발생 시 추적 해제
        if g.state == .began || g.state == .changed {
            stopFollowingOnUserInteraction()
        }
    }
    
    // 조작 감지 시 공통 처리 로직 (경우의 수 1,2,3 반영)
    private func stopFollowingOnUserInteraction() {
        // 1, 2. 평상시엔 지도를 조작하면 추적과 회전을 중지
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
                
                // 1. 사용자가 다른 화면(상세 경로 등)에 있다면 무조건 메인으로 강제 이동
                self.navigationController?.popToRootViewController(animated: true)
                
                // 2. 백그라운드에서 즉시 알람 종료 통신 및 지도/UI 초기화 실행
                self.viewModel.alarmDelete()
                self.exitButtonTapped()
                
                // 3. 안내용 팝업 띄우기 (화면 이동이 끝난 0.3초 뒤에 띄워서 자연스럽게)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.showArrivalPopup()
                }
            }
            .store(in: &cancellables)
    }
    
    private func showArrivalPopup() {
        // 이미 팝업이 떠 있다면 무시 (중복 방지)
        if presentedViewController is AtchaPopupViewController { return }
        
        let popupVM = AtchaPopupViewModel(info: .arrive)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.modalPresentationStyle = .overFullScreen
        popupVC.modalTransitionStyle = .crossDissolve // 부드럽게 나타나고 사라짐
        
        popupVC.confirmButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: false)
            // 팝업을 닫을 때 다음 알람을 위해 매니저 초기화
            HomeArrivalManager.shared.reset()
        }, for: .touchUpInside)
        
        self.present(popupVC, animated: false)
    }
    
    private func observeAlarmTimeout() {
        NotificationCenter.default.publisher(for: NSNotification.Name("alarmDidTimeout"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // 1. 무조건 메인으로 강제 이동
                self.navigationController?.popToRootViewController(animated: true)
                
                // 2. 백그라운드 취소 로직
                self.viewModel.alarmDelete()
                self.exitButtonTapped()
                
                if let coord = self.viewModel.currentLocation {
                    self.mapContainerView.setupCenter(location: coord)
                    self.viewModel.selectedLocation = coord // 주소도 다시 검색
                } else {
                    self.viewModel.setupLocation()
                }
                
                // 3. 타임아웃 팝업 띄우기
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showAlarmTimeoutPopup()
                }
            }
            .store(in: &cancellables)
    }
}
