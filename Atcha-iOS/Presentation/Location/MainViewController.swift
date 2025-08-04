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
    private let lastTrainView: LastTrainSearchBottomView = LastTrainSearchBottomView()
    private let lastTrainDepartView: LastTrainDepartBottomView = LastTrainDepartBottomView()
    private let flagImageView: UIImageView = UIImageView()
    private let myPageButton: UIButton = UIButton()
    private let loactionButton: UIButton = UIButton()
    private let atchaImageView: UIImageView = UIImageView()
    private let ballonView: AtchaBallon = AtchaBallon()
    
    private var firstAddress: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.setLoading(true)
        setupUI()
        setupAutoLayout()
        bindView()
    }
    
    private func setupUI() {
        view.addSubViews(
            mapContainerView,
            flagImageView,
            atchaImageView,
            lastTrainView,
            myPageButton,
            loactionButton,
            lastTrainDepartView,
            ballonView
        )
        
        mapContainerView.delegate = self
        
        lastTrainView.isHidden = false
        lastTrainDepartView.isHidden = true
        
        configureButton(myPageButton,
                        imageName: "mypage-filled",
                        action: #selector(didTapMyPageButton))
        configureButton(loactionButton,
                        imageName: "mylocation-filled",
                        action: #selector(didTapLocationButton))
        flagImageView.image = UIImage.settingLocationMark
        atchaImageView.image = UIImage.atcha
        ballonView.setupTitle(bottomMessage: "여기서 막차 놓치면 택시비")
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
        lastTrainView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        lastTrainDepartView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        myPageButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        loactionButton.snp.makeConstraints { make in
            make.bottom.equalTo(lastTrainView.snp.top).inset(-16)
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
            make.bottom.equalTo(lastTrainView.snp.top).inset(24)
        }
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(lastTrainView.snp.top).inset(30)
        }
    }
}

// MARK: - Bindings
extension MainViewController {
    
    private func bindView() {
        bindLastTrainViewActions()
        bindLastTrainDepartViewActions()
        bindAddressUpdates()
        bindCurrentLocationUpdates()
        bindSelectedLocationUpdates()
        bindLegPathUpdates()
        bindTaxiFareUpdates()
    }
    
    // MARK: - View Actions
    private func bindLastTrainViewActions() {
        lastTrainView.actionPublisher
            .sink { [weak self] in self?.handleLastTrainViewAction($0) }
            .store(in: &cancellables)
    }
    
    private func handleLastTrainViewAction(_ action: LastTrainSearchBottomView.Action) {
        switch action {
        case .currentTapped:
            viewModel.handleRoute(route: .changeCourse)
        case .searchTapped:
            viewModel.handleRoute(route: .courseSearch(
                startLat: "", startLon: "", startAddress: ""
            ))
        }
    }
    
    private func bindLastTrainDepartViewActions() {
        lastTrainDepartView.actionPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.handleLastTrainDepartAction($0) }
            .store(in: &cancellables)
    }
    
    private func handleLastTrainDepartAction(_ action: LastTrainDepartBottomView.Action) {
        switch action {
        case .exitTapped:
            viewModel.requestPermissionAndStartTracking()
            viewModel.removeLegInfoAndAddress()
            AlarmManager.shared.stopAlarm()
            
            lastTrainView.isHidden = false
            flagImageView.isHidden = false
            lastTrainDepartView.isHidden = true
            updateAtchaImageConstraint(relativeTo: lastTrainView)
            mapContainerView.clearMapView()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self else { return }
                view.showToast(message: "알림이 종료되었어요")
            }
            
        case .detailRoadMapTapped:
            viewModel.handleRoute(route: .detailRoute(address: "", infos: LegInfo(pathInfo: [], trafficInfo: [], busInfo: [])))
            print("detailRoadMapTapped 누르기")
        case .locationTapped:
            ballonView.setupTitle(bottomMessage: "위치를 변경하려면 알림을 종료해야 해요")
        case .reloadTapped:
            print("reloadTapped 누르기")
        case .timeTapped:
            ballonView.setupTitle(topMessage: "이때쯤 자리에서 출발하면 돼요", bottomMessage: "현재 교통 상황 기준으로,\n출발 시간이 가까워질수록 더 정확해져요")
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
        
        let title = (address == firstAddress) ? "현위치 : \(address)" : address
        lastTrainView.setupCurrentLocationTitle(title)
    }
    
    private func bindCurrentLocationUpdates() {
        viewModel.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.mapContainerView.setupCenter(location: $0) }
            .store(in: &cancellables)
    }
    
    private func bindSelectedLocationUpdates() {
        viewModel.$selectedLocation
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.mapContainerView.updateUserMarker(location: $0) }
            .store(in: &cancellables)
    }
    
    private func bindLegPathUpdates() {
        viewModel.$legPathInfos
            .filter { !$0.isEmpty }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleLegPathInfos($0) }
            .store(in: &cancellables)
        
        viewModel.$legTrafficInfos
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.lastTrainDepartView.setupTimeAfterAlarm(infos: $0) }
            .store(in: &cancellables)
    }
    
    private func handleLegPathInfos(_ infos: [LegPathInfo]) {
        lastTrainView.isHidden = true
        lastTrainDepartView.isHidden = false
        flagImageView.isHidden = true
        updateAtchaImageConstraint(relativeTo: lastTrainDepartView)
        ballonView.setupTitle(bottomMessage: "이때쯤 자리에서 출발하면 돼요")
        
        if let time = infos.first?.departureDateTime,
           let (hour, minute) = time.toHourMinute() {
            lastTrainDepartView.setupTime(hour: hour, minute: minute)
        }
        
        lastTrainDepartView.setupLoaction(location: viewModel.address)
        addRouteLine(infos: infos)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            view.showToast(message: "알림이 등록되었어요.")
        }
    }
    
    private func addRouteLine(infos: [LegPathInfo]) {
        var shapeStrings: [String] = []
        var colors: [UIColor] = []
        var images: [UIImage] = []
        var allCoordinates: [CLLocationCoordinate2D] = []  // ✅ 전체 좌표 수집
        
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
    
    private func bindTaxiFareUpdates() {
        viewModel.$taxiFare
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.updateTaxiFare($0) }
            .store(in: &cancellables)
    }
    
    private func updateTaxiFare(_ fare: Double) {
        let fareStr = String(format: "%.0f", fare)
        ballonView.setupTitle(bottomMessage: "여기서 막차 놓치면 택시비 : 약 \(fareStr)원")
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


extension MainViewController {
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.viewModel.setupLocation()
            self.hideLoading()
            
            let wrapper = UserDefaultsWrapper()
            if let legInfo: LegInfo = wrapper.object(forKey: UserDefaultsWrapper.Key.legInfo.rawValue, of: LegInfo.self),
               let address: String = wrapper.string(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue) {
                self.viewModel.drawRoute(address: address, infos: legInfo)
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
