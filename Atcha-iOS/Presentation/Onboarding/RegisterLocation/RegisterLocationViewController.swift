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
        
        setupMapView()
        setupUI()
        setupBottomUI()
        setupTapGesture()
        startUpdatingCurrentLocation()
        
        locationService.startHeadingUpdates(delegate: self)
        
        backOnlyNavigationBar.onTapBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - RegisterLocation Base UI
    private func setupUI() {
        view.addSubview(backOnlyNavigationBar)
        
        backOnlyNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
        }
    }
    
    // MARK: - TMap Seting
    private func setupMapView() {
        mapView.setApiKey(Bundle.main.tMapKey)
        mapView.delegate = self
        locationSettingImage.image = UIImage.settingLocationMark
        
        view.addSubViews(mapView)
        
        mapView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    // MARK: - Bottom UI
    private func setupBottomUI() {
        
        registerButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            
            self.onRegisterCompleted?(self.currentSelectedPlaceName, self.currentSelectedAddress, self.initialCoordinate.latitude, self.initialCoordinate.longitude)
            
            if let homeVC = self.navigationController?.viewControllers.first(where: { $0 is HomeRegisterViewController }) {
                self.navigationController?.popToViewController(homeVC, animated: true)
            }
        }, for: .touchUpInside)
        
        currentImage.image = UIImage.mylocationFilled.withRenderingMode(.alwaysOriginal)
        
        bottomView.backgroundColor = AtchaColor.gray950
        bottomView.layer.cornerRadius = 20
        bottomView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomView.clipsToBounds = true
        
        nameLabel.attributedText = AtchaFont.H5_SB_17(placeName, color: AtchaColor.white)
        addressLabel.attributedText = AtchaFont.Body_R_14(address, color: AtchaColor.gray200)
        
        let stackLabel = UIStackView(arrangedSubviews: [nameLabel, addressLabel])
        stackLabel.axis = .vertical
        stackLabel.spacing = 4
        stackLabel.alignment = .leading
        
        bottomView.addSubViews(stackLabel, registerButton)
        
        view.addSubview(bottomView)
        view.addSubview(currentImage)
        
        
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
    
    // MARK: - currentLocation Tapped
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCurrentLocationTapped))
        currentImage.isUserInteractionEnabled = true
        currentImage.addGestureRecognizer(tapGesture)
    }
    
    
    @objc private func handleCurrentLocationTapped() {
        viewModel.onboardingUseCase.requestCurrentLocation { [weak self] coordinate in
            guard let self = self, let coordinate = coordinate else {
                print("❌ 현재 위치 가져오기 실패")
                return
            }
            
            Task {
                do {
                    let response = try await self.viewModel.reverseGeocodeLocation(
                        lat: coordinate.latitude,
                        lon: coordinate.longitude
                    )
                    
                    let placeName = response.name
                    let address = response.address
                    
                    DispatchQueue.main.async {
                        self.initialCoordinate = coordinate
                        self.mapView.setCenter(coordinate)
                        self.nameLabel.attributedText = AtchaFont.H5_SB_17(placeName, color: AtchaColor.white)
                        self.addressLabel.attributedText = AtchaFont.Body_R_14(address, color: AtchaColor.gray200)
                        self.currentSelectedPlaceName = placeName
                        self.currentSelectedAddress = address
                    }
                } catch {
                    print("❌ 장소 변환 실패: \(error)")
                }
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
                    // 좌표 갱신
                    self.currentLocationMarker?.position = coordinate
                    
                    if self.currentLocationMarker?.map != nil {
                        // 마커 제거해서 깜빡임
                        self.currentLocationMarker?.map = nil
                    } else {
                        // 마커 다시 추가하면서 최신 heading 각도로 아이콘 갱신
                        if let heading = self.latestHeading?.trueHeading {
                            let rotatedImage = UIImage.currentLocationMark.rotated(by: CGFloat(heading))
                            self.currentLocationMarker?.icon = rotatedImage
                        }
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
        
        //지도랑 같이 나타나게 설정
        view.addSubview(locationSettingImage)
        
        locationSettingImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(250)
            make.height.equalTo(65)
            make.width.equalTo(48)
        }
    }
    
    // MARK: - 지도 변화 시 이벤트 발생 함수
    func mapViewDidChangeBounds() {
        guard let centerCoord = mapView.getCenter() else {
            print("center coordinate is nil")
            return
        }
        
        Task {
            do {
                let response = try await viewModel.reverseGeocodeLocation(
                    lat: centerCoord.latitude,
                    lon: centerCoord.longitude
                )
                
                let placeName = response.name
                let address = response.address
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.initialCoordinate = centerCoord
                    self.nameLabel.attributedText = AtchaFont.H5_SB_17(placeName, color: AtchaColor.white)
                    self.addressLabel.attributedText = AtchaFont.Body_R_14(address, color: AtchaColor.gray200)
                    self.currentSelectedPlaceName = placeName
                    self.currentSelectedAddress = address
                }
            } catch {
                print("reverseGeocode 실패: \(error)")
            }
        }
    }
    
    
}

extension RegisterLocationViewController: CLLocationManagerDelegate {
    
    // MARK: - 바라보는 방향에 따른 마커 변화
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.latestHeading = newHeading
    }
}
