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
    private var atchaImageBottomConstraint: Constraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            atchaImageBottomConstraint = make.bottom.equalTo(lastTrainView.snp.top).inset(24).constraint
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
            view.showToast(message: "알림이 종료되었어요")
            lastTrainView.isHidden = false
            lastTrainDepartView.isHidden = true
            updateAtchaImageConstraint(relativeTo: lastTrainView)
        case .detailRoadMapTapped:
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
    }
    
    private func handleLegPathInfos(_ infos: [LegPathInfo]) {
        view.showToast(message: "알림이 등록되었어요.")
        lastTrainView.isHidden = true
        lastTrainDepartView.isHidden = false
        updateAtchaImageConstraint(relativeTo: lastTrainDepartView)
        ballonView.setupTitle(bottomMessage: "이때쯤 자리에서 출발하면 돼요")
        
        if let time = infos.first?.departureDateTime,
           let (hour, minute) = time.toHourMinute() {
            lastTrainDepartView.setupTime(hour: hour, minute: minute)
        }
        
        lastTrainDepartView.setupLoaction(location: viewModel.address)
        addRouteLine(infos: infos)
    }
    
//    private func addRouteLine(infos: [LegPathInfo]) {
//        infos.forEach { info in
//            
//            print("info : \(info.mode)")
//            
//            switch info.mode {
//            case .bus:
//                mapContainerView.addTrafficLine(passShape: info.passShape ?? "")
//            case .subway:
//                mapContainerView.addTrafficLine(passShape: info.passShape ?? "")
//            case .walk:
//                info.step?.forEach { step in
//                    mapContainerView.addTrafficLine(passShape: step.linestring ?? "")
//                }
//            default: break
//            }
//        }
//    }
    
    private func addRouteLine(infos: [LegPathInfo]) {
        infos.forEach { info in
            var shapeStrings: [String] = []
            var colors: [UIColor] = []
            
            switch info.mode {
            case .bus, .subway:
                if let shape = info.passShape, !shape.isEmpty {
                    shapeStrings.append(shape)
                    colors.append(info.mode?.getColor(for: info.type ?? "") ?? .magenta)
                }

            case .walk:
                let walkShapes = info.step?.compactMap { $0.linestring }.filter { !$0.isEmpty } ?? []
                let merged = walkShapes.joined(separator: " ")
                if !merged.isEmpty {
                    shapeStrings.append(merged)
                    colors.append(.gray200)
                }

            default:
                break
            }

            // passShape들을 기반으로 선 그리기
//            shapeStrings.forEach { shape in
//                mapContainerView.addTrafficLine(passShape: shape, color: )
//            }
            zip(shapeStrings, colors).forEach { shape, color in
                print("color : \(color)")
                print("shapeStrings : \(shapeStrings)")
                mapContainerView.addTrafficLine(passShape: shape, color: color)
            }
        }
    }
    
//    private func addRouteLine(infos: [LegPathInfo]) {
//        infos.forEach { info in
//            let color: UIColor
//            switch info.mode {
//            case .bus:
//                color = info.mode?.getColor(for: info.type ?? "") ?? .systemBlue
//            case .subway:
//                color = info.mode?.getColor(for: info.type ?? "") ?? .systemPurple
//            case .walk:
//                color = .gray
//            default:
//                color = .lightGray
//            }
//
//            switch info.mode {
//            case .bus, .subway:
//                if let shape = info.passShape, !shape.isEmpty {
//                    mapContainerView.addTrafficLine(passShape: shape, color: color)
//                }
//
//            case .walk:
//                let walkShapes = info.step?
//                    .compactMap { $0.linestring }
//                    .filter { !$0.isEmpty } ?? []
//
//                walkShapes.forEach { linestring in
//                    mapContainerView.addTrafficLine(passShape: linestring, color: color)
//                }
//
//            default:
//                break
//            }
//        }
//    }
    
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
    private func updateAtchaImageConstraint(relativeTo view: UIView, inset: CGFloat = 24) {
        atchaImageBottomConstraint?.deactivate()
        atchaImageView.snp.makeConstraints {
            self.atchaImageBottomConstraint = $0
                .bottom
                .equalTo(view.snp.top)
                .inset(inset)
                .constraint
        }
    }
}


extension MainViewController {
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        viewModel.setupLocation()
        
        let passShape = "127.025347,37.637628 127.025619,37.637881 127.026825,37.638997 127.027403,37.639531 127.028386,37.638886 127.031444,37.636886 127.032253,37.636358 127.033556,37.635517 127.033622,37.635489 127.033839,37.635386 127.034283,37.635272 127.034531,37.635169 127.035389,37.634658 127.035700,37.634483 127.035917,37.634406 127.036078,37.634367 127.036086,37.634367 127.036769,37.634194 127.037456,37.634025 127.037678,37.633950 127.037931,37.633797 127.038625,37.632883 127.038728,37.632750 127.039133,37.632214 127.039147,37.632194 127.039272,37.632053 127.039544,37.631814 127.040014,37.631500 127.040017,37.631497"
//        mapContainerView.addTrafficLine(passShape: passShape)
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
