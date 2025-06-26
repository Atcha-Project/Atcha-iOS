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
    private var mapView: TMapView = TMapView()
    private let bottomView: UIView = UIView()
    private let nameLabel: UILabel = UILabel()
    private let addressLabel: UILabel = UILabel()
    private let currentImage: UIImageView = UIImageView()
    private let registerButton: AtchaButton = AtchaButton(text: "우리집 등록", size: .h48, style: .filled(.primary))
    
    private let initialCoordinate: CLLocationCoordinate2D
    private let placeName: String
    private let address: String
    private var currentSelectedPlaceName: String
    private var currentSelectedAddress: String
    
    var onRegisterCompleted: ((String, String) -> Void)?
    
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
        
        setupMapView()
        setupUI()
        setupBottomUI()
        setupTapGesture()
        
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
        mapView.setZoom(15)
        
        view.addSubview(mapView)
        
        
        mapView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    // MARK: - Bottom UI
    private func setupBottomUI() {
        
        registerButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            
            self.onRegisterCompleted?(self.currentSelectedPlaceName, self.currentSelectedAddress)
            
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
        LocationService.shared.requestLocation { [weak self] coordinate in
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
}

extension RegisterLocationViewController: TMapViewDelegate {
    
    func mapViewDidFinishLoadingMap() {
        print("지도 로딩 완료")
        mapView.setCenter(initialCoordinate)
        mapView.setMapType(.Night)
    }
}
