//
//  CourseSettingViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/18/25.
//

import UIKit
import SnapKit
import CoreLocation
import TMapSDK

final class CourseSettingViewController: BaseViewController<CourseSettingViewModel>, TMapWrapperDelegate {
    
    private let backButton: UIButton = UIButton()
    private let mapContainerView: TMapContainerView = TMapContainerView()
    private let settingBottomView: OriginSettingBottomView = OriginSettingBottomView()
    private let flagImageView: UIImageView = UIImageView()
    private let currentLoactionButton: UIButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        setupBackButton()
        bindView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        AmplitudeManager.shared.trackScreen(.origin_setting)
    }
    
    private func setupUI() {
        view.addSubViews(
            mapContainerView,
            flagImageView,
            currentLoactionButton,
            settingBottomView,
            backButton
        )
        
        mapContainerView.delegate = self
        flagImageView.image = UIImage.settingLocationMark
        flagImageView.isUserInteractionEnabled = false
        configureButton(currentLoactionButton, imageName: "mylocation-filled", action: #selector(didTapLocationButton))
        backButton.setImage(UIImage.chevronLeft, for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = .black
        backButton.clipsToBounds = true
        backButton.setCornerRadius(18)
    }
    
    private func configureButton(_ button: UIButton, imageName: String, action: Selector) {
        button.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func bindView() {
        viewModel.bindView()
        settingBottomView.actionPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .settingTapped:
                    guard let startCoord = viewModel.currentLocation else {
                        view.showToast(message: "현재 위치를 확인 중이에요. 잠시 후 다시 시도해 주세요.")
                        return
                    }
                    
                    Task { [weak self] in
                        guard let self else { return }
                        
                        let ok = await viewModel.checkServiceRegion(
                            lat: startCoord.latitude,
                            lon: startCoord.longitude
                        )
                        
                        guard ok else {
                            await MainActor.run {
                                self.view.showToast(message: "앗차는 현재 서울, 경기, 인천에서만 이용 가능해요")
                            }
                            return
                        }
                        
                        let wrapper = UserDefaultsWrapper.shared
                        let endLatStr = wrapper.string(forKey: UserDefaultsWrapper.Key.homeLat.rawValue) ?? "37.554722"
                        let endLonStr = wrapper.string(forKey: UserDefaultsWrapper.Key.homeLon.rawValue) ?? "126.970833"
                        
                        guard let endLat = Double(endLatStr),
                              let endLon = Double(endLonStr) else {
                            await MainActor.run {
                                self.view.showToast(message: "저장된 목적지 좌표가 잘못되었어요.")
                            }
                            return
                        }
                        
                        let endCoord = CLLocationCoordinate2D(latitude: endLat, longitude: endLon)
                        
                        guard !ProximityManager.shared.isWithinThreshold(from: startCoord, to: endCoord) else {
                            await MainActor.run {
                                self.view.showToast(message: "이동하려는 거리가 매우 가까워요")
                            }
                            return
                        }
                        
                        await MainActor.run {
                            self.viewModel.userDidTapSettingButton()
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        viewModel.$locationInfo
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                guard let self else { return }
                settingBottomView.setupLocationTitle(location.name, location.address)
            }
            .store(in: &cancellables)
        
        viewModel.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }
                mapContainerView.setupCenter(location: location)
            }
            .store(in: &cancellables)
    }
    
    private func setupAutoLayout() {
        flagImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(mapContainerView.snp.centerY)
            make.height.equalTo(63)
            make.width.equalTo(48)
        }
        
        currentLoactionButton.snp.makeConstraints { make in
            make.bottom.equalTo(settingBottomView.snp.top).inset(-16)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(40)
        }
        
        settingBottomView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(170)
        }
        
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(settingBottomView.snp.top).inset(30)
        }
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.width.height.equalTo(36)
        }
    }
    
    deinit {
        activePermissionToast?.hideImmediately()
    }
}

extension CourseSettingViewController {
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        mapView.mapView.isZoomEnable = true
        viewModel.setupInitialLocation()
    }
    
    @objc private func didTapLocationButton() {
        ensureLocationPermissionOrShowToast()
        viewModel.setupLocation()
    }
    
    private func setupBackButton() {
        backButton.addTarget(self,
                             action: #selector(backButtonTapped),
                             for: .touchUpInside)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Delegate
extension CourseSettingViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
    func mapViewDidStartScroll(_ mapView: TMapWrapper) {}
}
