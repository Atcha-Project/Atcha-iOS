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

final class MainViewController: BaseViewController<MainViewModel>,
                                TMapWrapperDelegate {
    
    private let mapContainerView: TMapContainerView = TMapContainerView()
    private let lastTrainSearchView: LastTrainSearchBottomView = LastTrainSearchBottomView() // 알람 등록 전
    private let lastTrainDepartView: LastTrainDepartBottomView = LastTrainDepartBottomView() // 알람 등록 이후
    //    private let lastTrainRealTimeView: LastTrainRealTimeBottomView = LastTrainRealTimeBottomView() // 알람 등록 이후, 시간 지남
    //    private let lastTrainArrivalView: LastTrainArrivalBottomView = LastTrainArrivalBottomView() // 알람 등록 이후, 시간 지남
    
    private let flagImageView: UIImageView = UIImageView()
    private let myPageButton: UIButton = UIButton()
    private let loactionButton: UIButton = UIButton()
    //    private let atchaImageView: UIImageView = UIImageView()
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
    
    // 홈 화면 상호작용 추적용 플래그
    private var didTouchMap: Int = 0          // 지도 드래그/선택 여부
    private var didTapCurrentLocation: Int = 0// ‘현위치’ 버튼 사용 여부
    private var didUseTextInput: Int = 0
    private var pinnedPreBalloon: BalloonContent?
    private let balloonInitialDelayFirst: TimeInterval = 0.7   // 첫 노출 700ms
    private let balloonInitialDelaySecond: TimeInterval = 1.5  // (2개일 때) 두 번째 1500ms
    private let balloonHold: TimeInterval = 2.5                // 유지 2500ms
    private let balloonFade: TimeInterval = 0.25               // 페이드 250ms
    
    // 큐/상태
    private enum BalloonContent: Equatable {
        case text(top: String?, bottom: String)
        case separation(gray: String, white: String) // (택시비: 회색+흰색 분리용)
    }
    
    private enum BalloonScope {
        case pre     // 알람 등록 전에서만
        case next      // 알람 등록 이후
    }
    
    private var balloonQueue: [(content: BalloonContent, delay: TimeInterval, scope: BalloonScope)] = []
    private var isBalloonShowing = false
    private var hasShownInitialBalloon = false
    
    // 최신 값 보관(비동기 합치기)
    private var latestIsServiceRegion: Bool?
    private var latestFareString: String?
    private var lastShownBalloon: BalloonContent?
    private var lastShownScope: BalloonScope?
    
    private var postAlarmMessages: [BalloonContent] = []
    private var postAlarmIndex = 0
    private var firstPostBalloonGeneration = 0
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let isAlarmRegistered = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) ?? false
        
        if !isAlarmRegistered {
            AmplitudeManager.shared.timerStart("notification_registration_duration")
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.onNetworkReconnect = { [weak self] in
            self?.mapContainerView.reloadMapView()
        }
        
        viewModel.setLoading(true)
        
        setupUI()
        setupAutoLayout()
        bindView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.viewModel.setupLocation()
            self?.hideLoading()
        }
    }
    
    private func setupUI() {
        view.addSubViews(
            mapContainerView,
            flagImageView,
            atchaImageView,
            lastTrainSearchView,
            myPageButton,
            loactionButton,
            lastTrainDepartView,
            //            lastTrainRealTimeView,
            //            lastTrainArrivalView,
            ballonView
        )
        
        mapContainerView.delegate = self
        configureButton(myPageButton,
                        imageName: "mypage-filled",
                        action: #selector(didTapMyPageButton))
        configureButton(loactionButton,
                        imageName: "mylocation-filled",
                        action: #selector(didTapLocationButton))
        flagImageView.image = UIImage.settingLocationMark
        //        atchaImageView.image = UIImage.atcha
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
        //        lastTrainRealTimeView.snp.makeConstraints { make in
        //            make.horizontalEdges.equalToSuperview()
        //            make.bottom.equalToSuperview()
        //        }
        //        lastTrainArrivalView.snp.makeConstraints { make in
        //            make.horizontalEdges.equalToSuperview()
        //            make.bottom.equalToSuperview()
        //        }
        myPageButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        loactionButton.snp.makeConstraints { make in
            make.bottom.equalTo(lastTrainSearchView.snp.top).inset(-16)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        ballonView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.bottom.equalTo(atchaImageView.snp.top).inset(-10)
        }
        atchaImageView.snp.makeConstraints { make in
            make.width.height.equalTo(64)
            make.leading.equalToSuperview().inset(8)
            make.bottom.equalTo(lastTrainSearchView.snp.top).inset(22)
        }
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(lastTrainSearchView.snp.top).inset(30)
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
        bindToastEvent()
    }
    
    // MARK: - bind Lock View
    private func bindLockView() {
        viewModel.$showLockView
            .filter { $0 }
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in self?.viewModel.handleRoute(route: .lockScreen(info: nil, address: nil)) }
            .store(in: &cancellables)
    }
    
    // MARK: - View Actions
    private func bindBottomViewActions() {
        lastTrainSearchView.actionPublisher
            .sink { [weak self] in self?.handleSearchViewAction($0) }
            .store(in: &cancellables)
        
        //        lastTrainRealTimeView.actionPublisher
        //            .sink { [weak self] in self?.handleRealTimeViewAction($0) }
        //            .store(in: &cancellables)
        
        lastTrainDepartView.actionPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.handleTrainDepartAction($0) }
            .store(in: &cancellables)
        
        //        lastTrainArrivalView.actionPublisher
        //            .receive(on: RunLoop.main)
        //            .sink { [weak self] in self?.handleArrivalViewAction($0) }
        //            .store(in: &cancellables)
    }
    
    private func bindToastEvent() {
        viewModel.$pendingToast
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self else { return }
                    view.showToast(message: message)
                }
                self?.viewModel.pendingToast = nil
            }
            .store(in: &cancellables)
    }
    
    
    private func handleSearchViewAction(_ action: LastTrainSearchBottomView.Action) {
        switch action {
        case .currentTapped:
            viewModel.handleRoute(route: .changeCourse(
                location: Location(name: "", lat: 0.0, lon: 0.0, businessCategory: "", address: "", radius: "")))
            didUseTextInput += 1
        case .searchTapped:
            
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
            
            if didTouchMap - 2 == 0 && didTapCurrentLocation == 0 && didUseTextInput == 0 {
                AmplitudeManager.shared.track(
                    AmplitudeEvent.home_coursesearch_entered.rawValue,
                    [
                        "entered_direct": 1,
                        "entered_with_map_drag": 0,
                        "entered_with_current_location": 0,
                        "entered_with_input": 0
                        
                    ]
                )
            } else {
                AmplitudeManager.shared.track(
                    AmplitudeEvent.home_coursesearch_entered.rawValue,
                    [
                        "entered_direct": 0,
                        "entered_with_map_drag": didTouchMap - 1,
                        "entered_with_current_location": didTapCurrentLocation,
                        "entered_with_input": didUseTextInput
                        
                    ]
                )
            }
            
        }
    }
    
    //    private func handleRealTimeViewAction(_ action: LastTrainRealTimeBottomView.Action) {
    //        switch action {
    //        case .refreshBusTime, .reloadTapped:
    //            break
    //            // TODO: 새로운 통신으로 변경하기
    //            //            viewModel.getBusRealTime()
    //        case .exitTapped:
    //            showAlarmExitPopup()
    //        case .detailRoadMapTapped: viewModel.handleRoute(route: .detailRoute(address: "",
    //                                                                             infos: LegInfo(pathInfo: [], trafficInfo: [], busInfo: []),
    //                                                                             context: .afterReigster)
    //        )
    //        case .finishAlarm: viewModel.bottomType = .finish
    //        }
    //    }
    
    private func handleTrainDepartAction(_ action: LastTrainDepartBottomView.Action) {
        switch action {
        case .exitTapped:
            showAlarmExitPopup()
            AmplitudeManager.shared.track(
                AmplitudeEvent.alert_end_popup_1.rawValue,
                [
                    "clicked": 1
                ]
            )
            
        case .detailRoadMapTapped:
            viewModel.handleRoute(route: .detailRoute(address: "",
                                                      infos: LegInfo(pathInfo: [], trafficInfo: [], busInfo: []),
                                                      context: .afterReigster)
            )
            AmplitudeManager.shared.track(
                AmplitudeEvent.home_itinerary_clicked.rawValue,
                [
                    "clicked": 1
                ]
            )
        case .locationTapped:
            enqueueNextBalloon(.text(top: nil, bottom: "위치를 변경하려면 알람을 종료해야 해요"))
            AmplitudeManager.shared.track(
                AmplitudeEvent.home_route_clicked.rawValue,
                [
                    "clicked": 1
                ]
            )
        case .reloadTapped:
            viewModel.refreshDepatrueTime()
        case .timeTapped:
            enqueueNextBalloon(.text(top: "이때쯤 자리에서 출발하면 돼요", bottom: "현재 교통 상황 기준으로,\n출발 시간이 가까워질수록 더 정확해져요"))
        }
    }
    
    //    private func handleArrivalViewAction(_ action: LastTrainArrivalBottomView.Action) {
    //        switch action {
    //        case .exitTapped:
    //            showAlarmExitPopup()
    //        case .detailRoadMapTapped: viewModel.handleRoute(route: .detailRoute(address: "",
    //                                                                             infos: LegInfo(pathInfo: [], trafficInfo: [], busInfo: []),
    //                                                                             context: .afterReigster))
    //        }
    //    }
    
    private func showAlarmExitPopup() {
        let popupVM = AtchaPopupViewModel(info: .alarm)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.cancelButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: true)
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
        viewModel.bottomType = .search
        
        mapContainerView.clearMapView()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            view.showToast(message: "알람이 종료되었어요")
            UserDefaultsWrapper.shared.set(false, forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue)
            AmplitudeManager.shared.timerEndSeconds("notification_registration_duration")
            AmplitudeManager.shared.timerStart("notification_registration_duration")
        }
    }
    
    // MARK: - ViewModel Bindings
    private func bindCurrentLocationUpdates() {
        viewModel.$currentLocation
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mapContainerView.setupCenter(location: $0) }
            .store(in: &cancellables)
    }
    
    private func bindAddressUpdates() {
        viewModel.$address
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] addr in
                guard let self else { return }
                self.updateAddress(addr)
                
                if self.hasShownInitialBalloon {
                    if self.latestIsServiceRegion == false {
                        // 알람 등록 전에서만
                        self.enqueuePreAlarmBalloon(
                            .text(top: "지도를 움직여 출발지를 설정해 봐요",
                                  bottom: "서울, 경기, 인천 내에서만 사용할 수 있어요")
                        )
                    }
                } else {
                    self.tryShowInitialBalloonIfNeeded()
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
        didTouchMap += 1
    }
    
    private func bindSelectedLocationUpdates() {
        viewModel.$selectedLocation
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.mapContainerView.updateUserMarker(location: $0) }
            .store(in: &cancellables)
    }
    
    private func bindAddressDescriptionUpdates() {
        viewModel.$addressDesc
            .receive(on: RunLoop.main)
            .sink { [weak self] desc in
                self?.lastTrainDepartView.setupLoaction(location: desc)
                //                self?.lastTrainArrivalView.setupLoaction(location: desc)
                //                self?.lastTrainRealTimeView.setupLoaction(location: desc)
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
                    self?.lastTrainDepartView.setupLegInfo(info: info)
                    //                case .detail:
                    //                    self?.viewModel.handleRoute(route: .detailRoute(address: "",
                    //                                                                    infos: LegInfo(pathInfo: [], trafficInfo: [], busInfo: []),
                    //                                                                    context: .afterReigster))
                    //                case .realTime: do {}
                    //                    self?.lastTrainRealTimeView.setupLegInfo(info: info)
                    //                case .finish:
                    //                    break
                    //                    self?.lastTrainArrivalView.setupLegInfo(info: info)
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
        
        //        viewModel.$busRealTimeInfo
        //            .compactMap { $0 }
        //            .receive(on: RunLoop.main)
        //            .sink { [weak self] info in
        //                self?.lastTrainRealTimeView.setupBusRealTime(realTime: info)
        //            }
        //            .store(in: &cancellables)
        
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
        //        lastTrainRealTimeView.isHidden = true
        flagImageView.isHidden = true
        lastTrainSearchView.isHidden = true
        lastTrainDepartView.isHidden = true
        //        lastTrainArrivalView.isHidden = true
        
        switch type {
            //        case .realTime: do {}
            //            lastTrainRealTimeView.isHidden = false
        case .departure:
            cancelBalloonQueueAndHide()
            lastTrainDepartView.isHidden = false
            viewModel.startAlarmTimer()
            setupPostAlarmMessages()
            
            firstPostBalloonGeneration += 1
            let myGen = firstPostBalloonGeneration
            
            // 200ms 뒤에 첫 풍선 예약 (여기서 3번 호출돼도 OK)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let self = self else { return }
                guard myGen == self.firstPostBalloonGeneration else { return }
                guard self.viewModel.bottomType == .departure else { return }
                
                self.enqueueNextBalloon(self.postAlarmMessages[0], delay: 0)
                
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.atchaImageView.stop()
                self?.atchaImageView.start()
            }
            
        case .detail:
            cancelBalloonQueueAndHide()
            lastTrainDepartView.isHidden = false
        case .search:
            cancelBalloonQueueAndHide()
            // 타이머/뷰 상태 기존 로직
            viewModel.stopAlarmTimer()
            viewModel.stopFinishAlarmTimer()
            lastTrainSearchView.isHidden = false
            flagImageView.isHidden = false
            mapContainerView.clearMapView()
            updateAtchaImageConstraint(relativeTo: lastTrainSearchView)
            
            hasShownInitialBalloon = false
            showInitialPreAlarmBalloons(force: true)
            //        case .detail:
            //            viewModel.handleRoute(route: .detailRoute(address: "",
            //                                                      infos: LegInfo(pathInfo: [], trafficInfo: [], busInfo: []),
            //                                                      context: .afterReigster))
            //        case .finish:
            //            lastTrainSearchView.isHidden = false // 원상복구
            //            lastTrainArrivalView.isHidden = false
            //            viewModel.endAlarmTimer()
        default: do {}
        }
    }
    
    private func bindTaxiFareUpdates() {
        viewModel.$taxiFare
            .compactMap { $0 }
            .map { Int($0) }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] fareInt in
                guard let self else { return }
                let fareStr = self.decimalFormatter.string(from: NSNumber(value: fareInt)) ?? "\(fareInt)"
                self.latestFareString = fareStr
                
                // 알람 등록 전 + 서비스 가능: 항상 분리 풍선으로 고정/갱신
                if self.isPreAlarmBalloonActive(), self.latestIsServiceRegion == true {
                    self.showOrUpdatePreBalloon(
                        .separation(gray: "여기서 막차 놓치면 택시비 ", white: "약 \(fareStr)원")
                    )
                }
                
                // 등록 후 회전 메시지의 마지막(택시비)도 유지
                if !self.postAlarmMessages.isEmpty {
                    self.postAlarmMessages[self.postAlarmMessages.count - 1] =
                        .separation(gray: "여기서 막차 놓치면 택시비 ", white: "약 \(fareStr)원")
                }
            }
            .store(in: &cancellables)
    }
    
    private func bindServiceRegionUpdates() {
        viewModel.$isServiceRegion
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] ok in
                guard let self else { return }
                let previous = self.latestIsServiceRegion
                self.latestIsServiceRegion = ok
                
                switch ok {
                case .some(true):
                    self.lastTrainSearchView.updateSearchEnabled(true)
                    if previous == nil {
                        // 첫 진입 시 강제 표시
                        self.showInitialPreAlarmBalloons(force: true)
                    } else if self.isPreAlarmBalloonActive() {
                        if let fare = self.latestFareString {
                            // 금액 있으면 분리 풍선
                            self.showOrUpdatePreBalloon(
                                .separation(gray: "여기서 막차 놓치면 택시비 ", white: "약 \(fare)원")
                            )
                        } else {
                            // 금액 아직 없으면 로딩 텍스트
                            self.showOrUpdatePreBalloon(
                                .text(top: "지도를 움직여 출발지를 설정해 봐요",
                                      bottom: "택시비를 불러오는 중이에요")
                            )
                        }
                    }
                    
                case .some(false):
                    self.lastTrainSearchView.updateSearchEnabled(false)
                    if previous == nil {
                        self.showInitialPreAlarmBalloons(force: true)
                    } else if self.isPreAlarmBalloonActive() {
                        self.showOrUpdatePreBalloon(
                            .text(top: "지도를 움직여 출발지를 설정해 봐요",
                                  bottom: "서울, 경기, 인천 내에서만 사용할 수 있어요")
                        )
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
            make.width.height.equalTo(64)
            make.leading.equalToSuperview().inset(8)
            make.bottom.equalTo(view.snp.top).inset(24)
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
            self.viewModel.setupLocation()
            self.hideLoading()
            
            let wrapper = UserDefaultsWrapper.shared
            if let legInfo: LegInfo = wrapper.object(forKey: UserDefaultsWrapper.Key.legInfo.rawValue, of: LegInfo.self),
               let address: String = wrapper.string(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue) {
                self.viewModel.drawRoute(address: address, info: legInfo)
                return
            }
        }
    }
    
    @objc private func didTapMyPageButton() {
        viewModel.handleRoute(route: .myPage)
    }
    
    @objc private func didTapLocationButton() {
        viewModel.setupLocation()
        
        didTapCurrentLocation += 1
    }
    
    @objc private func handleBallonTap() {
        atchaImageView.stop()
        atchaImageView.start()
        
        let scope = lastShownScope
        
        switch scope {
        case .pre:
            AmplitudeManager.shared.track(AmplitudeEvent.character_clicked_after_alarm.rawValue, ["clicked": 1])
        case .next:
            guard !postAlarmMessages.isEmpty else { return }
            
            if postAlarmIndex < 1 { postAlarmIndex = 1 }
            let content = postAlarmMessages[postAlarmIndex]
            
            // 기존 큐 무시하고 바로 표시
            showOrUpdateImmediateBalloon(content)
            
            let cycleCount = postAlarmMessages.count - 1
            postAlarmIndex = 1 + ((postAlarmIndex - 1 + 1) % cycleCount)
            
            AmplitudeManager.shared.track(AmplitudeEvent.character_clicked_before_alarm.rawValue, ["clicked": 1])
        case .none:
            break
        }
    }
    
    private func enqueueInternal(_ content: BalloonContent,
                                 delay: TimeInterval = 0,
                                 hold: TimeInterval? = nil,
                                 scope: BalloonScope) {
        // 스코프 검사
        if scope == .pre && !isPreAlarmBalloonActive() { return }
        balloonQueue.append((content, delay, scope))
        drainBalloonQueue(hold: hold ?? balloonHold)
    }
    
    // 알람 등록 전에서만 노출 (택시비/서비스지역/초기풍선)
    private func enqueuePreAlarmBalloon(_ content: BalloonContent,
                                        delay: TimeInterval = 0,
                                        hold: TimeInterval? = nil) {
        showOrUpdatePreBalloon(content, delay: delay, animated: true)
    }
    
    // 등록 후 안내
    private func enqueueNextBalloon(_ content: BalloonContent,
                                    delay: TimeInterval = 0,
                                    hold: TimeInterval? = nil) {
        enqueueInternal(content, delay: delay, hold: hold, scope: .next)
    }
    
    private func drainBalloonQueue(hold: TimeInterval) {
        guard !isBalloonShowing, let next = balloonQueue.first else { return }
        isBalloonShowing = true
        balloonQueue.removeFirst()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + next.delay) { [weak self] in
            guard let self else { return }
            
            self.ballonView.layer.removeAllAnimations()
            self.view.bringSubviewToFront(self.ballonView)
            
            switch next.content {
            case .text(let top, let bottom):
                if let top = top {
                    self.ballonView.setupTitle(topMessage: top, bottomMessage: bottom)
                } else {
                    self.ballonView.setupTitle(bottomMessage: bottom)
                }
            case .separation(let gray, let white):
                self.ballonView.separationTitle(grayMessage: gray, whiteMessage: white)
            }
            
            // 마지막 말풍선/스코프 저장
            self.lastShownBalloon = next.content
            self.lastShownScope = next.scope
            
            self.ballonView.alpha = 0
            self.ballonView.isHidden = false
            UIView.animate(withDuration: self.balloonFade, delay: 0, options: .curveEaseInOut) {
                self.ballonView.alpha = 1
            } completion: { _ in
                UIView.animate(withDuration: self.balloonFade,
                               delay: hold,
                               options: .curveEaseInOut) {
                    self.ballonView.alpha = 0
                } completion: { _ in
                    self.ballonView.isHidden = true
                    self.isBalloonShowing = false
                    self.drainBalloonQueue(hold: hold)
                }
            }
        }
    }
    
    private func tryShowInitialBalloonIfNeeded() {
        showInitialPreAlarmBalloons(force: false)
    }
    
    /// 알람 등록 전: 큐/페이드아웃 없이 바로 표시(고정)
    private func showOrUpdatePreBalloon(_ content: BalloonContent,
                                        delay: TimeInterval = 0,
                                        animated: Bool = true) {
        guard isPreAlarmBalloonActive() else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            
            // 동일 콘텐츠면 불필요 업데이트 방지 (원하면 지워도 됨)
            if self.pinnedPreBalloon == content, self.lastShownScope == .pre {
                return
            }
            
            self.ballonView.layer.removeAllAnimations()
            self.view.bringSubviewToFront(self.ballonView)
            
            switch content {
            case .text(let top, let bottom):
                if let top = top {
                    self.ballonView.setupTitle(topMessage: top, bottomMessage: bottom)
                } else {
                    self.ballonView.setupTitle(bottomMessage: bottom)
                }
            case .separation(let gray, let white):
                self.ballonView.separationTitle(grayMessage: gray, whiteMessage: white)
            }
            
            if self.ballonView.isHidden {
                self.ballonView.alpha = 0
                self.ballonView.isHidden = false
                UIView.animate(withDuration: animated ? self.balloonFade : 0) {
                    self.ballonView.alpha = 1
                }
            } else {
                // 이미 떠있을 때는 자연스럽게 내용만 갈아끼우고 알파는 유지
            }
            
            // 마지막/고정 상태 갱신
            self.lastShownBalloon = content
            self.lastShownScope = .pre
            self.pinnedPreBalloon = content
        }
    }
    
    private func showInitialPreAlarmBalloons(force: Bool = false) {
        guard force || !hasShownInitialBalloon,
              let isService = latestIsServiceRegion else { return }
        
        let d1 = balloonInitialDelayFirst
        
        if isService {
            if let fare = latestFareString {
                // 금액 있으면 바로 분리 풍선
                showOrUpdatePreBalloon(
                    .separation(gray: "여기서 막차 놓치면 택시비 ", white: "약 \(fare)원"),
                    delay: d1
                )
            } else {
                // 금액 없으면 일단 로딩 텍스트 -> 금액 들어오면 위 (1)에서 자동 교체됨
                showOrUpdatePreBalloon(
                    .text(top: "지도를 움직여 출발지를 설정해 봐요",
                          bottom: "택시비를 불러오는 중이에요"),
                    delay: d1
                )
            }
        } else {
            // 서비스 불가 지역 문구
            showOrUpdatePreBalloon(
                .text(top: "지도를 움직여 출발지를 설정해 봐요",
                      bottom: "서울, 경기, 인천 내에서만 사용할 수 있어요"),
                delay: d1
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.atchaImageView.stop()
            self?.atchaImageView.start()
        }
        hasShownInitialBalloon = true
    }
    
    private func showOrUpdateImmediateBalloon(_ content: BalloonContent) {
        // 기존 애니메이션 & 예약 취소
        balloonQueue.removeAll()
        ballonView.layer.removeAllAnimations()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideImmediateBalloon), object: nil)
        
        // 말풍선 내용 업데이트
        switch content {
        case .text(let top, let bottom):
            if let top = top {
                ballonView.setupTitle(topMessage: top, bottomMessage: bottom)
            } else {
                ballonView.setupTitle(bottomMessage: bottom)
            }
        case .separation(let gray, let white):
            ballonView.separationTitle(grayMessage: gray, whiteMessage: white)
        }
        
        // 즉시 표시 (페이드인)
        ballonView.isHidden = false
        ballonView.alpha = 0
        view.bringSubviewToFront(ballonView)
        
        UIView.animate(withDuration: 0.25) {
            self.ballonView.alpha = 1
        }
        
        // 마지막 터치 기준으로 3초 뒤 페이드아웃 예약
        perform(#selector(hideImmediateBalloon), with: nil, afterDelay: 3.0)
        
        // 상태 저장
        lastShownBalloon = content
        lastShownScope = .next
        pinnedPreBalloon = content
    }

    
    @objc private func hideImmediateBalloon() {
        UIView.animate(withDuration: 0.25, animations: {
            self.ballonView.alpha = 0
        }) { _ in
            self.ballonView.isHidden = true
        }
    }
    
    private func isPreAlarmBalloonActive() -> Bool {
        return viewModel.bottomType == .search
    }
    
    private func cancelBalloonQueueAndHide() {
        balloonQueue.removeAll()
        ballonView.layer.removeAllAnimations()
        ballonView.isHidden = true
        ballonView.alpha = 0
        isBalloonShowing = false
        
        // 프리 고정말풍선 상태도 리셋
        pinnedPreBalloon = nil
        if lastShownScope == .pre { lastShownBalloon = nil }
    }
    
    private func setupPostAlarmMessages() {
        let fareStr = latestFareString ?? "12,000"
        postAlarmMessages = [
            .text(top: "이때 자리에서 출발하면 돼요", bottom: "교통 상황에 따라 시간이 달라질 수 있어요"),
            .text(top: nil, bottom: "교통 상황에 따라 시간이 달라질 수 있어요"),
            .text(top: nil, bottom: "시간에 맞춰 알림을 드릴게요"),
            .text(top: nil, bottom: "믿을 수 있는 공공 데이터를 활용하고 있어요"),
            .separation(gray: "여기서 막차 놓치면 택시비 ", white: "약 \(fareStr)원")
        ]
        postAlarmIndex = 1
    }
}

// MARK: - Delegate
extension MainViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
}
