//
//  RegisterLocationViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/26/25.
//

import UIKit
import SnapKit
import TMapSDK
import CoreLocation

class RegisterLocationViewController: BaseViewController<RegisterLocationViewModel> {
    
    private let backOnlyNavigationBar: BackOnlyNavigationBar = AtchaNavigationBar.backOnly()
    private let bottomView: UIView = UIView()
    private let nameLabel: UILabel = UILabel()
    private let addressLabel: UILabel = UILabel()
    private let currentImage: UIImageView = UIImageView()
    private let registerButton: AtchaButton = AtchaButton(text: "우리집 등록", size: .h48, style: .filled(.primary))
    private var initialCoordinate: CLLocationCoordinate2D
    private let placeName: String
    private let address: String
    private var currentSelectedPlaceName: String
    private var currentSelectedAddress: String
    private var mapView: TMapView = TMapView()
    private let locationSettingImage: UIImageView = UIImageView()
    private var locationTimer: Timer?
    private var currentLocationMarker: TMapMarker?
    private var isMarkerVisible = true
    private let locationService = LocationService()
    private var latestHeading: CLHeading?
    
    
    var onRegisterCompleted: ((String, String, Double, Double) -> Void)?
    
    init(viewModel: RegisterLocationViewModel, coordinate: CLLocationCoordinate2D, placeName: String, address: String) {
        self.initialCoordinate = coordinate
        self.placeName = placeName
        self.address = address
        self.currentSelectedPlaceName = placeName
        self.currentSelectedAddress = address
        super.init(viewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopUpdatingCurrentLocation()
        bind()
        setupUI()
        setupTapAtction()
        setupNavigationBarCallbacks()
        startUpdatingCurrentLocation()
        
        locationService.startHeadingUpdates(delegate: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopUpdatingCurrentLocation()
        locationService.stopHeadingUpdates()
        currentLocationMarker?.map = nil
    }
    
    // MARK: - ViewModel 바인딩
    private func bind() {
        viewModel.$currentCoordinate
            .receive(on: DispatchQueue.main)
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] coordinate in
                guard let self, let coordinate else { return }
                self.initialCoordinate = coordinate
            }
            .store(in: &cancellables)
        
        viewModel.$placeName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] placeName in
                guard let placeName else { return }
                self?.nameLabel.attributedText = AtchaFont.H4_SB_17(placeName, color: AtchaColor.white)
                self?.currentSelectedPlaceName = placeName
            }
            .store(in: &cancellables)
        
        viewModel.$address
            .receive(on: DispatchQueue.main)
            .sink { [weak self] address in
                guard let address else { return }
                self?.addressLabel.attributedText = AtchaFont.B6_R_14(address, color: AtchaColor.gray200)
                self?.currentSelectedAddress = address
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 기본 UI
    private func setupUI() {
        mapView.setApiKey(Bundle.main.tMapKey)
        mapView.delegate = self
        locationSettingImage.image = UIImage.settingLocationMark
        
        currentImage.image = UIImage.mylocationFilled.withRenderingMode(.alwaysOriginal)
        
        bottomView.backgroundColor = AtchaColor.gray950
        bottomView.layer.cornerRadius = 20
        bottomView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomView.clipsToBounds = true
        
        nameLabel.attributedText = AtchaFont.H4_SB_17(placeName, color: AtchaColor.white)
        addressLabel.attributedText = AtchaFont.B6_R_14(address, color: AtchaColor.gray200)
        
        let stackLabel = UIStackView(arrangedSubviews: [nameLabel, addressLabel])
        stackLabel.axis = .vertical
        stackLabel.spacing = 4
        stackLabel.alignment = .leading
        
        bottomView.addSubViews(stackLabel, registerButton)
        
        view.addSubViews(mapView)
        view.addSubview(backOnlyNavigationBar)
        view.addSubview(bottomView)
        view.addSubview(currentImage)
        
        mapView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        backOnlyNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
        
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(170)
        }
        
        stackLabel.snp.makeConstraints { make in
            make.top.equalTo(bottomView.snp.top).inset(32)
            make.leading.equalTo(bottomView.snp.leading).offset(16)
            make.trailing.equalTo(bottomView.snp.trailing).inset(16)
        }
        
        registerButton.snp.makeConstraints { make in
            make.top.equalTo(stackLabel.snp.bottom).offset(24)
            make.leading.equalTo(bottomView.snp.leading).offset(16)
            make.trailing.equalTo(bottomView.snp.trailing).inset(16)
        }
        
        currentImage.snp.makeConstraints { make in
            make.bottom.equalTo(bottomView.snp.top).offset(-16)
            make.trailing.equalToSuperview().inset(17)
            make.size.equalTo(36)
        }
    }
    
    // MARK: - 터치 액션 모음
    private func setupTapAtction() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCurrentLocationTapped))
        currentImage.isUserInteractionEnabled = true
        currentImage.addGestureRecognizer(tapGesture)
        
        registerButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            
            self.onRegisterCompleted?(
                self.currentSelectedPlaceName,
                self.currentSelectedAddress,
                self.initialCoordinate.latitude,
                self.initialCoordinate.longitude
            )
            
        }, for: .touchUpInside)
    }
    
    // MARK: - 네비게이션 바 콜백
    private func setupNavigationBarCallbacks() {
        backOnlyNavigationBar.onTapBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - 현재 위치
    @objc private func handleCurrentLocationTapped() {
        viewModel.handleCurrentLocation { [weak self] coordinate, placeName, address in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.initialCoordinate = coordinate
                self.mapView.setCenter(coordinate)
                self.nameLabel.attributedText = AtchaFont.H4_SB_17(placeName, color: AtchaColor.white)
                self.addressLabel.attributedText = AtchaFont.B6_R_14(address, color: AtchaColor.gray200)
                self.currentSelectedPlaceName = placeName
                self.currentSelectedAddress = address
            }
        }
    }
    
    // MARK: - 실시간 현위치 추적 시작
    private func startUpdatingCurrentLocation() {
        locationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateCurrentLocation()
        }
    }
    
    // MARK: - 실시간 현위치 추적 정지
    private func stopUpdatingCurrentLocation() {
        locationTimer?.invalidate()
        locationTimer = nil
    }
    
    // MARK: - 실시간 현위치 표시를 위한 마커 추가
    private func updateCurrentLocation() {
        viewModel.onboardingUseCase.requestCurrentLocation { [weak self] coordinate in
            guard let self, let coordinate = coordinate else { return }
            
            DispatchQueue.main.async {
                if self.currentLocationMarker == nil {
                    let marker = TMapMarker(position: coordinate)
                    let originalImage = UIImage.currentLocationMark
                    if let heading = self.latestHeading?.trueHeading {
                        marker.icon = originalImage.rotated(by: CGFloat(heading))
                    }
                    marker.map = self.mapView
                    self.currentLocationMarker = marker
                } else {
                    self.currentLocationMarker?.position = coordinate
                    
                    if let heading = self.latestHeading?.trueHeading {
                        let rotatedImage = UIImage.currentLocationMark.rotated(by: CGFloat(heading))
                        self.currentLocationMarker?.map = nil
                        self.currentLocationMarker?.icon = rotatedImage
                        self.currentLocationMarker?.map = self.mapView
                    }
                }
            }
        }
    }
}

extension RegisterLocationViewController: TMapViewDelegate {
    
    // MARK: - 지도 렌더링 완료 시 설정 함수
    func mapViewDidFinishLoadingMap() {
        mapView.setCenter(initialCoordinate)
        mapView.setMapType(.Night)
        mapView.setZoom(50)
        
        view.addSubview(locationSettingImage)
        
        locationSettingImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(250)
            make.height.equalTo(65)
            make.width.equalTo(48)
        }
    }
    
    // MARK: - 터치 종료 시 주소 불러오기
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let centerCoord = mapView.getCenter() else {
            print("center coordinate is nil")
            return
        }
        
        viewModel.updateLocationByMapMovement(
            lat: centerCoord.latitude,
            lon: centerCoord.longitude
        )
    }
}

extension RegisterLocationViewController: CLLocationManagerDelegate {
    
    // MARK: - 바라보는 방향에 따른 마커 변화
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.latestHeading = newHeading
    }
}
