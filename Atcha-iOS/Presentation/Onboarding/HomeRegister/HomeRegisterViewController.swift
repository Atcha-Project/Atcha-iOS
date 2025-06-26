//
//  HomeRegisterViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import UIKit
import SnapKit
import CoreLocation

enum LocationSelectionState {
    case none
    case selected(name: String, address: String)
}

class HomeRegisterViewController: BaseViewController<HomeRegisterViewModel> {
    
    private var locationState: LocationSelectionState = .none {
        didSet { updateLocationView() }
    }
    
    private let titleLabel: UILabel = UILabel()
    private let subTitleLabel: UILabel = UILabel()
    private let searchLocationContainer: UIView = UIView()
    private let searchLocationLabel: UILabel = UILabel()
    private let locationNameLabel: UILabel = UILabel()
    private let locationAddressLabel: UILabel = UILabel()
    
    private let currentLocationButton: UIButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        updateLocationView()
    }
    
    // MARK: - Home Register UI
    private func setupUI() {
        view.backgroundColor = AtchaColor.gray950
        
        titleLabel.attributedText = AtchaFont.H3_B_22("우리 집을 등록해 보세요", color: AtchaColor.white)
        subTitleLabel.attributedText = AtchaFont.Body_R_15("출발지에서 우리집까지 빠르게 막차 찾을 수 있어요.", color: AtchaColor.gray200)
        
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 12
        labelStack.alignment = .leading
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSearchLocationTapped))
        searchLocationContainer.addGestureRecognizer(tapGesture)
        searchLocationContainer.isUserInteractionEnabled = true
        
        view.addSubViews(labelStack, searchLocationContainer, currentLocationButton)
        
        labelStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(72)
            make.leading.equalTo(view.snp.leading).inset(16)
        }
        
        searchLocationContainer.snp.makeConstraints { make in
            make.top.equalTo(labelStack.snp.bottom).offset(48)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
            make.centerX.equalToSuperview()
        }
        
        currentLocationButton.snp.makeConstraints { make in
            make.top.equalTo(searchLocationContainer.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
            make.centerX.equalToSuperview()
        }
        
    }
    
    // MARK: - 위치 선택/미선택 UI
    private func updateLocationView() {
        searchLocationContainer.subviews.forEach { $0.removeFromSuperview() }
        
        switch locationState {
        case .none:
            setupNoneStateUI()
        case .selected(let name, let address):
            setupSelectedStateUI(name: name, address: address)
        }
    }
    
    // MARK: - 위치 미선택 UI
    private func setupNoneStateUI() {
        searchLocationContainer.backgroundColor = AtchaColor.gray930
        searchLocationContainer.layer.cornerRadius = 10
        
        searchLocationLabel.attributedText = AtchaFont.Body_R_17("지번, 도로명, 건물명으로 검색", color: AtchaColor.gray400)
        searchLocationLabel.numberOfLines = 0
        searchLocationLabel.textAlignment = .left
        
        searchLocationContainer.addSubview(searchLocationLabel)
        searchLocationLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        setupLocationButton(title: "현 위치 찾기", icon: UIImage.placeFilled)
    }
    
    // MARK: - 위치 선택 UI
    private func setupSelectedStateUI(name: String, address: String) {
        searchLocationContainer.backgroundColor = .clear
        
        locationNameLabel.attributedText = AtchaFont.H6_SB_15(name, color: AtchaColor.white)
        locationAddressLabel.attributedText = AtchaFont.Body_R_14(address, color: AtchaColor.gray200)
        
        let labelStack = UIStackView(arrangedSubviews: [locationNameLabel, locationAddressLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 4
        labelStack.alignment = .leading
        
        searchLocationContainer.addSubview(labelStack)
        labelStack.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        setupLocationButton(title: "수정하기", icon: nil)
    }
    
    // MARK: - 위치 선택/미선택 버튼 UI
    private func setupLocationButton(title: String, icon: UIImage?) {
        currentLocationButton.backgroundColor = .clear
        currentLocationButton.layer.cornerRadius = 8
        currentLocationButton.layer.borderColor = AtchaColor.gray800.cgColor
        currentLocationButton.layer.borderWidth = 1
        currentLocationButton.setAttributedTitle(AtchaFont.Body_R_14(title, color: AtchaColor.white), for: .normal)
        currentLocationButton.tintColor = AtchaColor.white
        currentLocationButton.addTarget(self, action: #selector(handleCurrentLocationButtonTapped), for: .touchUpInside)
        
        if let icon = icon {
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            currentLocationButton.setImage(icon.withConfiguration(config), for: .normal)
            currentLocationButton.imageView?.contentMode = .scaleAspectFit
        } else {
            currentLocationButton.setImage(nil, for: .normal)
        }
    }
    
    // MARK: - Action Method
    @objc private func handleSearchLocationTapped() {
        let searchLocationVM = viewModel.makeSearchLocationViewModel()
        let vc = SearchLocationViewController(viewModel: searchLocationVM)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func handleCurrentLocationButtonTapped() {
        switch locationState {
        case .none:
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

                        let registerVM = self.viewModel.makeRegisterLocationViewModel()
                        let vc = RegisterLocationViewController(
                            viewModel: registerVM,
                            coordinate: coordinate,
                            placeName: placeName,
                            address: address
                        )
                        
                        vc.onRegisterCompleted = { [weak self] name, address in
                            self?.locationState = .selected(name: name, address: address)
                        }
                        self.navigationController?.pushViewController(vc, animated: true)
                        
                    } catch {
                        print("❌ 장소 변환 실패: \(error)")
                    }
                }
            }
            
        case .selected:
            // 이미 선택되어 있을 경우 → 검색 화면으로 이동
            let searchLocationVM = viewModel.makeSearchLocationViewModel()
            let vc = SearchLocationViewController(viewModel: searchLocationVM)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func updateLocation(name: String, address: String) {
        self.locationState = .selected(name: name, address: address)
    }
}
