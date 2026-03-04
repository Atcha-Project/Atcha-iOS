//
//  HomeFindViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/8/25.
//

import UIKit
import Foundation
import CoreLocation
import TMapSDK

final class HomeFindViewController: BaseViewController<HomeFindViewModel>,
                                    TMapWrapperDelegate {
    private let mapContainerView: TMapContainerView = TMapContainerView()
    private let bottomView: HomeRegisterBottomView = HomeRegisterBottomView()
    private let flagImageView: UIImageView = UIImageView()
    private let backButton: UIButton = UIButton()
    private let loactionButton: UIButton = UIButton()
    private let exitButton: UIButton = UIButton()

    var routeHandler: ((HomeRouter) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        setupBackButton()
        bindViewModel()
         
        handleInitialLocationFlow()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AmplitudeManager.shared.trackScreen(.home_setting)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        mapContainerView.deinitMapView()
    }
    
    private func setupUI() {
        view.addSubViews(mapContainerView,
                         flagImageView,
                         bottomView,
                         loactionButton,
                         backButton)
        
        mapContainerView.delegate = self
        flagImageView.image = UIImage.settingLocationMark
        backButton.setImage(UIImage.chevronLeft, for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = .black
        backButton.clipsToBounds = true
        backButton.setCornerRadius(18)
        
        configureButton(loactionButton,
                        imageName: "mylocation-filled",
                        action: #selector(didTapLocationButton))
    }
    
    private func bindViewModel() {
        bottomView.actionPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let coord = self.viewModel.currentLocation else { return }
                
                self.bottomView.isUserInteractionEnabled = false
                
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    let ok = await self.viewModel.checkServiceRegion(
                        lat: coord.latitude,
                        lon: coord.longitude
                    )
                    if ok {
                        self.viewModel.handleRegister()
                        if viewModel.context == .myPage {
                            self.navigationController?.popToViewController(ofType: HomeRegisterViewController.self)
                        }
                    } else {
                        AtchaToast(message: "앗차는 현재 서울, 경기, 인천에서만 이용 가능해요")
                            .show(in: self.view)
                    }
                    
                    self.bottomView.isUserInteractionEnabled = true
                }
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
        
        viewModel.$address
            .receive(on: DispatchQueue.main)
            .sink { [weak self] address in
                guard let self else { return }
                bottomView.setupAddressLabel(address: address)
            }
            .store(in: &cancellables)
        
        viewModel.$buildingName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                guard let self else { return }
                bottomView.setupNameLabel(name: name)
            }
            .store(in: &cancellables)
    }
    
    private func configureButton(_ button: UIButton, imageName: String, action: Selector) {
        button.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func setupAutoLayout() {
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalToSuperview()
        }
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.size.equalTo(36)
        }
        
        flagImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(mapContainerView.snp.centerY).offset(-63)
            make.height.equalTo(63)
            make.width.equalTo(48)
        }
        
        loactionButton.snp.makeConstraints { make in
            make.bottom.equalTo(bottomView.snp.top).inset(-16)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        
        bottomView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    private func handleInitialLocationFlow() {
        if viewModel.hasSavedLocation {
            viewModel.setupLocation()
            return
        }
        
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            Task { @MainActor in
                viewModel.setupLocation()
            }
        case .notDetermined:
            Task { @MainActor in
                await viewModel.applyDefaultLocationIfPermissionDenied()
            }
            
        case .denied, .restricted:
            Task { @MainActor in
                await viewModel.applyDefaultLocationIfPermissionDenied()
            }
            
        @unknown default:
            Task {}
        }
    }
    
    deinit {
        activePermissionToast?.hideImmediately()
    }
}

// MARK: - Action
extension HomeFindViewController {
    private func setupBackButton() {
        backButton.addTarget(self,
                             action: #selector(backButtonTapped),
                             for: .touchUpInside)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didTapLocationButton() {
        ensureLocationPermissionOrShowToast()
        viewModel.setupLocation()
    }
}

// MARK: - Delegate
extension HomeFindViewController {
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        if viewModel.hasSavedLocation {
            viewModel.setupLocation()
            return
        }

        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            viewModel.forceDeviceLocation = true
            viewModel.setupLocation()
        } else {
            Task { @MainActor in
                await viewModel.applyDefaultLocationIfPermissionDenied()
            }
        }
    }
    
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
    
    func mapViewDidStartScroll(_ mapView: TMapWrapper) {}
}

