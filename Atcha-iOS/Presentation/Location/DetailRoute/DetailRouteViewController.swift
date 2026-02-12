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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.setLoading(true)
        setupUI()
        setupAutoLayout()
        bindView()
        bindFollowLogic()
        installMapUserGestureDetector()
//
//#if DEBUG
//// ✅ 용산구청(대략) - 필요하면 조금씩 조절
//viewModel.mockLocation = CLLocationCoordinate2D(latitude: 37.5326, longitude: 126.9909)
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
        
        //        relaodButton.setImage(UIImage.refreshOutlined, for: .normal)
        //        relaodButton.tintColor = .white
        //        relaodButton.backgroundColor = .gray600
        //        relaodButton.clipsToBounds = true
        //        relaodButton.setCornerRadius(24)
        //        relaodButton.addTarget(self, action: #selector(didTapReload), for: .touchUpInside)
        
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
            .sink { [weak self] infos in self?.bottomSheet.setupRouteInfo(infos) }
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
        
//        viewModel.$currentLocation
//            .compactMap { $0 }
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] location in
//                guard let self else { return }
//                mapContainerView.updateUserMarker(location: location)
//                let offsetLatitude = location.latitude - 0.0003
//                let offsetLocation = CLLocationCoordinate2D(
//                    latitude: offsetLatitude,
//                    longitude: location.longitude
//                )
//    
//                mapContainerView.setupZoomCenter(location: offsetLocation)
//            }
//            .store(in: &cancellables)
//        viewModel.$currentLocation
//            .compactMap { $0 }
//            .receive(on: DispatchQueue.global(qos: .userInitiated))
//            .sink { [weak self] loc in
//                guard let self else { return }
//
//                let threshold: CLLocationDistance = 300.0
//
//                // trafficInfo와 pathInfo를 같은 leg 순서로 zip 한다는 가정
//                let pairs = zip(self.viewModel.legTrafficInfo, self.viewModel.legtPathInfo)
//
//                var near: Set<UUID> = []
//
//                for (traffic, path) in pairs {
//                    guard traffic.mode == path.mode else { continue }
//                    guard let shape = path.passShape, !shape.isEmpty else { continue }
//
//                    let coords = self.convertShapeToCoords(shape)
//                    let d = self.distanceToPolylineMeters(point: loc, polyline: coords)
//                    if d <= threshold {
//                        near.insert(traffic.id)
//                    }
//                }
//
//                DispatchQueue.main.async {
//                    self.viewModel.nearLegIDs = near
//                }
//            }
//            .store(in: &cancellables)
        
        viewModel.$nearLegIDs
            .receive(on: RunLoop.main)
            .sink { [weak self] near in
                self?.bottomSheet.updateProximityHighlight(nearLegIDs: near)
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
    }
    
    private func bindFollowLogic() {
        // 위치
        viewModel.$currentLocation
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] coord in
                guard let self else { return }

                mapContainerView.updateUserMarker(location: coord)

                if isAlarmFired {
                    // 알람 울린 후엔 계속 따라감
                    mapContainerView.setupZoomCenter(location: coord)
                    return
                }

                // 알람 전: 기본은 fit 고정. 단, 현위치 버튼으로 following 켰다면 이동
                if isFollowingUser {
                    mapContainerView.setupZoomCenter(location: coord)
                    return
                }

                // 알람 전 + following 꺼져있으면 center 건드리지 않음 (사용자가 보는 fit 유지)
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
        let busLegs = viewModel.legTrafficInfo.filter { $0.mode == .bus }
        let busCount = busLegs.count
        let hasSubway = viewModel.legTrafficInfo.contains { $0.mode == .subway }
        let hasLongWaitBus = busLegs.contains { ($0.targetBusTerm ?? 0) >= 40 }
        
        let isException = (busCount == 1) && (hasSubway == false)
        
        let shouldShowPopup = hasLongWaitBus && !isException
        
        let routeId = viewModel.infos.pathInfo.first?.routeId
        
        let alarmRequest = AlarmRequest(lastRouteId: routeId)
        let isAlarmRegistered = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.alarmRegister.rawValue) ?? false
        
        if isAlarmRegistered {
            if shouldShowPopup {
                showCoursePopup(alarmRequest)
            } else {
                showRe_RegisterPopup(alarmRequest)
            }
        } else {
            if shouldShowPopup {
                showCoursePopup(alarmRequest)
            } else {
                viewModel.alarmRegister(alarmRequest)
                viewModel.getAlarmTapped?(viewModel.address, viewModel.infos)
                let dwellSeconds = AmplitudeManager.shared.timerEndSeconds("alarm_dwell")
                AmplitudeManager.shared.track(
                    .another_alarm_register,
                    props(
                        AmplitudeProperty.dwellTime(seconds: dwellSeconds)
                    )
                )
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
