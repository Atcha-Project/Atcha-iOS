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
    private let atchaImageView: UIImageView = UIImageView()
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
        atchaImageView.image = UIImage.atcha
        ballonView.setupTitle(bottomMessage: "지도를 움직여 출발지를 설정해 봐요.")
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
        case .detailRoadMapTapped:
            viewModel.handleRoute(route: .detailRoute(address: "",
                                                      infos: LegInfo(pathInfo: [], trafficInfo: [], busInfo: []),
                                                      context: .afterReigster)
            )
        case .locationTapped:
            ballonView.setupTitle(bottomMessage: "위치를 변경하려면 알람을 종료해야 해요")
        case .reloadTapped:
            viewModel.refreshDepatrueTime()
        case .timeTapped:
            ballonView.setupTitle(topMessage: "이때쯤 자리에서 출발하면 돼요",
                                  bottomMessage: "현재 교통 상황 기준으로,\n출발 시간이 가까워질수록 더 정확해져요")
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
        }
    }
    
    // MARK: - ViewModel Bindings
    private func bindAddressUpdates() {
        viewModel.$address
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.updateAddress($0) }
            .store(in: &cancellables)
    }
    
    private func updateAddress(_ address: String) {
        if firstAddress == nil {
            firstAddress = address
        }
        
        let title = (address == firstAddress) ? "현위치: \(address)" : address
        lastTrainSearchView.setupCurrentLocationTitle(title)
    }
    
    private func bindCurrentLocationUpdates() {
        viewModel.$currentLocation
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mapContainerView.setupCenter(location: $0) }
            .store(in: &cancellables)
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
            lastTrainDepartView.isHidden = false
            viewModel.startAlarmTimer()
        case .detail:
            lastTrainDepartView.isHidden = false
        case .search:
            viewModel.stopAlarmTimer()
            viewModel.stopFinishAlarmTimer()
            lastTrainSearchView.isHidden = false
            flagImageView.isHidden = false
            mapContainerView.clearMapView()
            updateAtchaImageConstraint(relativeTo: lastTrainSearchView)
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
            .combineLatest(viewModel.$isServiceRegion)
            .filter { _, isService in isService == true }
            .map { fare, _ in fare }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] fare in
                self?.updateTaxiFare(fare)
            }
            .store(in: &cancellables)
    }
    
    private func updateTaxiFare(_ fare: Double) {
        guard fare.isFinite else { return }
        let fareInt = Int(fare)
        let fareStr = decimalFormatter.string(from: NSNumber(value: fareInt)) ?? "\(fareInt)"
        ballonView.separationTitle(
            grayMessage: "여기서 막차 놓치면 택시비 ",
            whiteMessage: "약 \(fareStr)원"
        )
    }
    
    private func bindServiceRegionUpdates() {
        viewModel.$isServiceRegion
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] ok in
                guard let self else { return }
                switch ok {
                case .some(true):
                    self.lastTrainSearchView.updateSearchEnabled(true)
                    if let fare = self.viewModel.taxiFare {
                        self.updateTaxiFare(fare)
                    }
                    
                case .some(false):
                    self.lastTrainSearchView.updateSearchEnabled(false)
                    self.ballonView.setupTitle(bottomMessage: "서울, 경기, 인천에서만 이용 가능해요")
                    
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

