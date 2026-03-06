//
//  DetailRouteViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import UIKit
import CoreLocation
import TMapSDK
import VSMSDK
import MapKit
import Combine

final class DetailRouteViewController: BaseViewController<DetailRouteViewModel>,
                                       TMapWrapperDelegate {
    private let mapContainerView: TMapContainerView = TMapContainerView()
    private let loactionButton: UIButton = UIButton()
    private let backButton: UIButton = UIButton()
    private var activityIndicator: UIActivityIndicatorView?
    private lazy var bottomSheet: DetailRouteInfoBottomView = DetailRouteInfoBottomView()
    //    private let relaodButton: UIButton = UIButton()
    private let refreshButton: RefreshView = RefreshView(background: .default)
    private var allCoordinates: [CLLocationCoordinate2D] = []
    private let registerContainer: UIView = UIView()
    private var registerGradient = CAGradientLayer()
    private let alarmRegisterButton: AtchaButton = AtchaButton(text: "막차 알람 받기", size: .h52, style: .filled(.primary), image: .bellOutlined)
    
    private var isFollowingUser = false
    private var shouldCenterToCurrentLocationOnce = false
    private var lastRouteFitApplied = false
    private var isAlarmFired: Bool {
        UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue) ?? false
    }
    private var legPolylineById: [UUID: [CLLocationCoordinate2D]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.setLoading(true)
        setupUI()
        setupAutoLayout()
        bindView()
        bindFollowLogic()
        installMapUserGestureDetector()
        bindAlarmFireStatus()
        //#if DEBUG
        //// ✅ 서울아산병원(대략)
        //viewModel.mockLocation = CLLocationCoordinate2D(latitude:37.566956, longitude: 126.979406)
        //viewModel.currentLocation = viewModel.mockLocation
        //#endif
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isAlarmFired && !allCoordinates.isEmpty {
            mapContainerView.adjustMapToFit(coordinates: allCoordinates)
            
            mapContainerView.snp.remakeConstraints { make in
                make.horizontalEdges.equalToSuperview()
                make.top.equalToSuperview()
                make.height.equalToSuperview().multipliedBy(0.65)
            }
        } else if isAlarmFired {
            mapContainerView.snp.remakeConstraints { make in
                make.horizontalEdges.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalToSuperview().inset(200)
            }
        }
        
        registerGradient.frame = registerContainer.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        AmplitudeManager.shared.trackScreen(.course_detail)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyMapModeOnAppearOrAlarmChange()
    }
    
    private func setupUI(context: DetailRouteContext) {
        switch context {
        case .beforeRegister:
            bottomSheet.bottomPadding(80)
            setupBeforeUI()
        case .afterReigster:
            bottomSheet.bottomPadding(0)
            setupAfterUI()
        }
    }
    
    // MARK: 알림 등록 이전 UI
    private func setupBeforeUI() {
        refreshButton.isHidden = true
        registerContainer.addSubview(alarmRegisterButton)
        registerContainer.backgroundColor = .clear
        view.addSubview(registerContainer)
        
        alarmRegisterButton.addTarget(self, action: #selector(didTapAlarmRegister), for: .touchUpInside)
        
        registerContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.snp.bottom)
            make.height.equalTo(160)
        }
        
        view.bringSubviewToFront(registerContainer)
        applyRegisterGradient()
        
        alarmRegisterButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40)
        }
    }
    
    private func applyRegisterGradient() {
        registerGradient.removeFromSuperlayer()
        registerGradient = CAGradientLayer()
        registerGradient.colors = [
            AtchaColor.black.withAlphaComponent(0.0).cgColor, // 위: 투명
            AtchaColor.black.withAlphaComponent(1.0).cgColor  // 아래: 불투명
        ]
        registerGradient.locations = [0.0, 1.0]
        registerGradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        registerGradient.endPoint   = CGPoint(x: 0.5, y: 1.0)
        registerContainer.layer.insertSublayer(registerGradient, at: 0)
    }
    
    
    // MARK: 알림 등록 이후 UI
    private func setupAfterUI() {
        refreshButton.isHidden = false
    }
    
    private func setupUI() {
        view.addSubViews(mapContainerView, loactionButton, bottomSheet, backButton, refreshButton)
        mapContainerView.delegate = self
        
        backButton.setImage(UIImage.chevronLeft, for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = .black
        backButton.clipsToBounds = true
        backButton.setCornerRadius(18)
        backButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        
        refreshButton.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapReload))
        refreshButton.addGestureRecognizer(tap)
        
        configureButton(loactionButton,
                        imageName: "mylocation-filled",
                        action: #selector(didTapLocationButton))
    }
    
    private func configureButton(_ button: UIButton, imageName: String, action: Selector) {
        button.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func setupAutoLayout() {
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.width.height.equalTo(36)
        }
        bottomSheet.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(view.frame.height * 0.5)
        }
        loactionButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-34)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        refreshButton.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.snp.bottom).inset(40)
        }
        
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.65)
        }
    }
    
    private func bindView() {
        viewModel.$legTrafficInfo
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] infos in
                guard let self else { return }
                self.bottomSheet.setupRouteInfo(infos)
                self.bottomSheet.updateProximityHighlight(nearLegIDs: self.viewModel.nearLegIDs)
            }
            .store(in: &cancellables)
        
        viewModel.$busRealTimeInfos
            .filter { $0.count > 0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] info in
                self?.bottomSheet.setupBusTimerLabel(info)
            }
            .store(in: &cancellables)
        
        viewModel.$subwayRealTimeInfos
            .receive(on: RunLoop.main)
            .sink { [weak self] infos in
                self?.bottomSheet.setupSubwayTimerLabel(infos)
            }
            .store(in: &cancellables)
        
        viewModel.$address
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] address in self?.bottomSheet.setupStartAddress(address) }
            .store(in: &cancellables)
        
        viewModel.$nearLegIDs
            .receive(on: RunLoop.main)
            .sink { [weak self] near in
                guard let self = self else { return }
                let idsToHighlight = self.isAlarmFired ? near : []
                self.bottomSheet.updateProximityHighlight(nearLegIDs: idsToHighlight)
            }
            .store(in: &cancellables)
        
        bottomSheet.onBusDetail = { [weak self] info in
            self?.viewModel.onBusDetail?(info)
            AmplitudeManager.shared.track(.bus_detail_click)
        }
        
        bottomSheet.getNewBusRealTime = { [weak self] in
            self?.viewModel.fetchInfo()
        }
        
        viewModel.$context
            .receive(on: RunLoop.main)
            .sink { [weak self] ctx in
                self?.setupUI(context: ctx)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(viewModel.$legTrafficInfo, viewModel.$legtPathInfo)
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] trafficInfos, pathInfos in
                guard let self else { return }
                guard !trafficInfos.isEmpty, !pathInfos.isEmpty else { return }
                
                var dict: [UUID: [CLLocationCoordinate2D]] = [:]
                
                for (traffic, path) in zip(trafficInfos, pathInfos) {
                    guard traffic.mode == path.mode else { continue }
                    
                    if let shape = path.passShape, !shape.isEmpty {
                        dict[traffic.id] = self.convertShapeToCoords(shape)
                        continue
                    }
                    
                    if let steps = path.step, !steps.isEmpty {
                        let merged = steps
                            .compactMap { $0.linestring }
                            .filter { !$0.isEmpty }
                            .joined(separator: " ")
                        
                        if !merged.isEmpty {
                            dict[traffic.id] = self.convertShapeToCoords(merged)
                        }
                    }
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.legPolylineById = dict
                }
            }
            .store(in: &cancellables)
    }
    
    private func bindFollowLogic() {
        // 위치
        viewModel.$currentLocation
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] coord in
                guard let self else { return }
                
                // 1) 유저 마커 업데이트 (메인)
                self.mapContainerView.updateUserMarker(location: coord)
                
                // 2) 지도 follow 로직 (메인)
                if self.isAlarmFired {
                    // 알람 울린 후엔 계속 따라감
                    self.mapContainerView.setupZoomCenter(location: coord)
                } else if self.isFollowingUser {
                    // 알람 전: following 켰을 때만 따라감
                    self.mapContainerView.setupZoomCenter(location: coord)
                }
                // else: fit 유지 (건드리지 않음)
                
                // 3) 근처(150m) 지나가면 반짝임 계산 (백그라운드)
                let threshold: CLLocationDistance = 150
                
                let polylines = self.legPolylineById
                let orderedLegs = self.viewModel.legTrafficInfo   // 화면 표시 순서(위→아래)
                
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard let self else { return }
                    
                    // 1) near 후보들을 Set으로 수집
                    var nearCandidates = Set<UUID>()
                    
                    for (id, polyline) in polylines {
                        let d = self.distanceToPolylineMeters(point: coord, polyline: polyline)
                        if d <= threshold {
                            nearCandidates.insert(id)
                        }
                    }
                    
                    // 2) "위에 있는 셀 우선" = orderedLegs 순서로 첫 매칭 1개만 남김
                    var picked: Set<UUID> = []
                    if let first = orderedLegs.first(where: { nearCandidates.contains($0.id) })?.id {
                        picked = [first]
                    }
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.viewModel.nearLegIDs = picked
                    }
                }
            }
            .store(in: &cancellables)
        
        // 헤딩
        viewModel.$deviceHeading
            .compactMap { $0 }
            .removeDuplicates(by: { abs($0 - $1) < 2 })
            .receive(on: RunLoop.main)
            .sink { [weak self] heading in
                guard let self else { return }
                guard isFollowingUser || isAlarmFired else { return }
                mapContainerView.setHeading(heading)
            }
            .store(in: &cancellables)
    }
    
    private func bindAlarmFireStatus() {
        // UserDefaults의 변화를 실시간으로 구독합니다.
        UserDefaults.standard.publisher(for: \.departureAlarmDidFire)
            .removeDuplicates() // 같은 값이 연속으로 들어오는 것 방지
            .receive(on: RunLoop.main)
            .sink { [weak self] isFired in
                guard let self = self else { return }
                
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
    
    private func addRouteLine(infos: [LegPathInfo]) {
        var shapeStrings: [String] = []
        var colors: [UIColor] = []
        var images: [UIImage] = []
        
        infos.forEach { info in
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
        
        mapContainerView.adjustMapToFit(coordinates: allCoordinates)
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
    
    @objc private func didTapAlarmRegister() {
        let hasConfigured = UserDefaults.standard.bool(forKey: "hasSeenAlarmSettingsSheet")
        if !hasConfigured {
            // 처음이라면? 설정 시트를 먼저 띄웁니다.
            self.presentPushAlarmSheet { [weak self] in
                // 시트 완료 시 플래그 저장 후 권한/등록 단계로 진행
                UserDefaults.standard.set(true, forKey: "hasSeenAlarmSettingsSheet")
                self?.handleAlarmPermissionAndRegistration()
            }
        } else {
            // 이미 설정해본 적이 있다면? 바로 권한 체크 및 등록 진행
            self.handleAlarmPermissionAndRegistration()
        }
    }
    
    private func presentPushAlarmSheet(completion: @escaping () -> Void) {
        let sheetVM = PushAlarmSheetViewModel()
        let sheetVC = PushAlarmSheetViewController(viewModel: sheetVM)
        
        // 뒷배경이 보이도록 설정
        sheetVC.modalPresentationStyle = .overFullScreen
        
        sheetVC.onComplete = {
            completion()
        }
        
        sheetVC.onDismiss = {
        }
        
        present(sheetVC, animated: false)
    }
    
    /// 2~3단계: 권한 확인 및 실제 서버 알람 등록 처리
    private func handleAlarmPermissionAndRegistration() {
        self.ensureAlarmPermissionAndExecute { [weak self] in
            guard let self = self else { return }
            
            // 여기서부터는 권한이 허용된 상태에서만 실행되는 기존 비즈니스 로직입니다.
            let busLegs = self.viewModel.legTrafficInfo.filter { $0.mode == .bus }
            let busCount = busLegs.count
            let hasSubway = self.viewModel.legTrafficInfo.contains { $0.mode == .subway }
            let hasLongWaitBus = busLegs.contains { ($0.targetBusTerm ?? 0) >= 40 }
            
            let isException = (busCount == 1) && (hasSubway == false)
            let shouldShowPopup = hasLongWaitBus && !isException
            
            let routeId = self.viewModel.infos.pathInfo.first?.routeId
            let alarmRequest = AlarmRequest(lastRouteId: routeId)
            let isAlarmRegistered = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) ?? false
            
            if isAlarmRegistered {
                // 이미 등록된 알람이 있을 때 (재등록/중복 팝업)
                if shouldShowPopup {
                    self.showCoursePopup(alarmRequest)
                } else {
                    self.showRe_RegisterPopup(alarmRequest)
                }
            } else {
                // 신규 알람 등록
                if shouldShowPopup {
                    self.showCoursePopup(alarmRequest)
                } else {
                    self.viewModel.alarmRegister(alarmRequest)
                    self.viewModel.getAlarmTapped?(self.viewModel.address, self.viewModel.infos)
                    
                    let dwellSeconds = AmplitudeManager.shared.timerEndSeconds("alarm_dwell")
                    AmplitudeManager.shared.track(
                        .another_alarm_register,
                        props(AmplitudeProperty.dwellTime(seconds: dwellSeconds))
                    )
                    
                    // 등록 완료 후 메인 지도로 이동 (필요시 호출)
                    self.navigationController?.popToMainViewControllerNoAnimation()
                }
            }
        }
    }
    
    private func applyMapModeOnAppearOrAlarmChange() {
        if isAlarmFired {
            // (2) 알람 울린 후: 무조건 따라가기 ON
            isFollowingUser = true
            shouldCenterToCurrentLocationOnce = true
            viewModel.startHeading()
            lastRouteFitApplied = false
        } else {
            // (1) 알람 울리기 전: 경로 전체 보이기 고정
            isFollowingUser = false
            shouldCenterToCurrentLocationOnce = false
            viewModel.stopHeading()
            
            // 화면 재진입 때마다 fit으로 "다시" 고정하려면 매번 호출
            mapContainerView.adjustMapToFit(coordinates: allCoordinates)
            lastRouteFitApplied = true
        }
    }
    
    deinit {
        activePermissionToast?.hideImmediately()
        mapContainerView.deinitMapView()
    }
}

// MARK: - Touch Event
extension DetailRouteViewController {
    @objc private func didTapClose() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didTapLocationButton() {
        ensureLocationPermissionOrShowToast()
        
        isFollowingUser = true
        shouldCenterToCurrentLocationOnce = true
        viewModel.startHeading()
        
        viewModel.setupLocation()
        
        mapContainerView.snp.remakeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(200)
        }
    }
    
    @objc private func didTapReload() {
        refreshButton.start()
        
        if !isAlarmFired {
            isFollowingUser = false
            shouldCenterToCurrentLocationOnce = false
            viewModel.stopHeading()
            
            mapContainerView.adjustMapToFit(coordinates: allCoordinates)
        }
        
        viewModel.fetchInfo()
        AmplitudeManager.shared.track(.course_refresh_click)
    }
}

// MARK: - Map Delegate
extension DetailRouteViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {}
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {}
    
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        viewModel.$legtPathInfo
            .filter { !$0.isEmpty }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.addRouteLine(infos: $0) }
            .store(in: &cancellables)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.hideLoading()
        }
    }
}

extension DetailRouteViewController {
    private func showCoursePopup(_ alarmRequest: AlarmRequest) {
        let popupVM = AtchaPopupViewModel(info: .course)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.confirmButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: false)
            self.viewModel.alarmRegister(alarmRequest)
            self.viewModel.getAlarmTapped?(self.viewModel.address, self.viewModel.infos)
            UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.popRegister.rawValue)
            
            let dwellSeconds = AmplitudeManager.shared.timerEndSeconds("alarm_dwell")
            AmplitudeManager.shared.track(
                .another_alarm_register,
                props(
                    AmplitudeProperty.dwellTime(seconds: dwellSeconds)
                )
            )
        }, for: .touchUpInside)
        
        popupVC.cancelButton.addAction(UIAction { [weak self, weak popupVC] _ in
            guard let _ = self else { return }
            popupVC?.dismiss(animated: false)
            
        }, for: .touchUpInside)
        
        popupVC.modalPresentationStyle = .overFullScreen
        present(popupVC, animated: false)
    }
    
    private func showRe_RegisterPopup(_ alarmRequest: AlarmRequest) {
        let popupVM = AtchaPopupViewModel(info: .re_register)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.confirmButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: false)
            self.viewModel.alarmRegister(alarmRequest)
            self.viewModel.getAlarmTapped?(self.viewModel.address, self.viewModel.infos)
            UserDefaultsWrapper.shared.set(true, forKey: UserDefaultsWrapper.Key.popRegister.rawValue)
            
            let dwellSeconds = AmplitudeManager.shared.timerEndSeconds("alarm_dwell")
            AmplitudeManager.shared.track(
                .another_alarm_register,
                props(
                    AmplitudeProperty.dwellTime(seconds: dwellSeconds)
                )
            )
        }, for: .touchUpInside)
        
        popupVC.cancelButton.addAction(UIAction { [weak self, weak popupVC] _ in
            guard let _ = self else { return }
            popupVC?.dismiss(animated: false)
            
        }, for: .touchUpInside)
        
        popupVC.modalPresentationStyle = .overFullScreen
        present(popupVC, animated: false)
    }
}

extension DetailRouteViewController {
    private func distanceToPolylineMeters(
        point: CLLocationCoordinate2D,
        polyline: [CLLocationCoordinate2D]
    ) -> CLLocationDistance {
        guard polyline.count >= 2 else { return .greatestFiniteMagnitude }
        
        let p = MKMapPoint(point)
        var best = CLLocationDistance.greatestFiniteMagnitude
        
        for i in 0..<(polyline.count - 1) {
            let a = MKMapPoint(polyline[i])
            let b = MKMapPoint(polyline[i + 1])
            
            let abx = b.x - a.x
            let aby = b.y - a.y
            let apx = p.x - a.x
            let apy = p.y - a.y
            
            let ab2 = abx*abx + aby*aby
            if ab2 == 0 { // 같은 점이면 점-점 거리
                best = min(best, p.distance(to: a))
                continue
            }
            
            // 투영 비율 t를 0~1로 clamp
            var t = (apx*abx + apy*aby) / ab2
            t = max(0, min(1, t))
            
            let closest = MKMapPoint(x: a.x + t*abx, y: a.y + t*aby)
            best = min(best, p.distance(to: closest))
        }
        
        return best
    }
}

extension DetailRouteViewController: UIGestureRecognizerDelegate {
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
        true
    }
    
    @objc private func userDidManipulateMap(_ g: UIGestureRecognizer) {
        if g.state == .began {
            isFollowingUser = false
            shouldCenterToCurrentLocationOnce = false
            viewModel.stopHeading()
        }
    }
}
