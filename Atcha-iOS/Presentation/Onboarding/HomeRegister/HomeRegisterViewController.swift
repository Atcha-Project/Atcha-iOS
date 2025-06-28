//
//  HomeRegisterViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import UIKit
import SnapKit
import CoreLocation

final class HomeRegisterViewController: BaseViewController<HomeRegisterViewModel> {
    
    private let titleLabel = UILabel()
    private let subTitleLabel = UILabel()
    private let searchLocationContainer = UIView()
    private let searchLocationLabel = UILabel()
    private let locationNameLabel = UILabel()
    private let locationAddressLabel = UILabel()
    private let currentLocationButton = UIButton()
    private lazy var nextButton = AtchaButton(
        text: "다음",
        size: .h52,
        style: .filled(.disabled)
    ) { [weak self] in
        guard let self, let location = self.viewModel.selectedLocation else { return }
        self.onNextTapped?(location)
    }
    
    var onNextTapped: ((SelectedLocation) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }
    
    // MARK: - ViewModel 바인딩
    private func bind() {
        viewModel.$locationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 기본 UI
    private func setupUI() {
        view.backgroundColor = AtchaColor.gray950
        
        titleLabel.attributedText = AtchaFont.H3_B_22("우리 집을 등록해 보세요", color: AtchaColor.white)
        subTitleLabel.attributedText = AtchaFont.Body_R_15("출발지에서 우리집까지 빠르게 막차 찾을 수 있어요.", color: AtchaColor.gray200)
        
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 12
        labelStack.alignment = .leading
        
        searchLocationContainer.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSearchTapped))
        searchLocationContainer.addGestureRecognizer(tapGesture)
        
        view.addSubViews(labelStack, searchLocationContainer, currentLocationButton, nextButton)
        
        labelStack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(72)
            make.leading.equalToSuperview().inset(16)
        }
        searchLocationContainer.snp.makeConstraints { make in
            make.top.equalTo(labelStack.snp.bottom).offset(48)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        currentLocationButton.snp.makeConstraints { make in
            make.top.equalTo(searchLocationContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        nextButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
    }
    
    // MARK: - UI 렌더링
    private func render(_ state: LocationSelectionState) {
        searchLocationContainer.subviews.forEach { $0.removeFromSuperview() }
        
        switch state {
        case .none:
            setupNoneStateUI()
        case .selected(let name, let address):
            setupSelectedStateUI(name: name, address: address)
        }
    }
    
    // MARK: - 장소 미선택 UI
    private func setupNoneStateUI() {
        searchLocationContainer.backgroundColor = AtchaColor.gray930
        searchLocationContainer.layer.cornerRadius = 10
        searchLocationLabel.attributedText = AtchaFont.Body_R_17("지번, 도로명, 건물명으로 검색", color: AtchaColor.gray400)
        searchLocationContainer.addSubview(searchLocationLabel)
        searchLocationLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        setupLocationButton(title: "현 위치 찾기", icon: UIImage.placeFilled)
        
        nextButton.isEnabled = false
        nextButton.updateStyle(text: "다음", style: .filled(.disabled))
    }
    
    // MARK: - 장소 선택 UI
    private func setupSelectedStateUI(name: String, address: String) {
        searchLocationContainer.backgroundColor = .clear
        locationNameLabel.attributedText = AtchaFont.H6_SB_15(name, color: AtchaColor.white)
        locationAddressLabel.attributedText = AtchaFont.Body_R_14(address, color: AtchaColor.gray200)
        
        let stack = UIStackView(arrangedSubviews: [locationNameLabel, locationAddressLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        searchLocationContainer.addSubview(stack)
        stack.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        setupLocationButton(title: "수정하기", icon: nil)
        
        nextButton.isEnabled = true
        nextButton.updateStyle(text: "다음", style: .filled(.primary))
    }
    
    // MARK: - 현위치 찾기 Button
    private func setupLocationButton(title: String, icon: UIImage?) {
        currentLocationButton.backgroundColor = .clear
        currentLocationButton.layer.cornerRadius = 8
        currentLocationButton.layer.borderWidth = 1
        currentLocationButton.layer.borderColor = AtchaColor.gray800.cgColor
        currentLocationButton.setAttributedTitle(AtchaFont.Body_R_14(title, color: .white), for: .normal)
        currentLocationButton.tintColor = .white
        
        currentLocationButton.addTarget(self, action: #selector(handleCurrentLocationTapped), for: .touchUpInside)
        
        if let icon {
            let config = UIImage.SymbolConfiguration(pointSize: 16)
            currentLocationButton.setImage(icon.withConfiguration(config), for: .normal)
        } else {
            currentLocationButton.setImage(nil, for: .normal)
        }
    }
    
    // MARK: - 장소 검색
    @objc private func handleSearchTapped() {
        let searchVM = viewModel.makeSearchLocationViewModel()
        let vc = SearchLocationViewController(viewModel: searchVM)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - 현위치 찾기
    @objc private func handleCurrentLocationTapped() {
        viewModel.handleCurrentLocation { [weak self] registerVM, coordinate, placeName, address in
            guard let self else { return }
            
            let vc = RegisterLocationViewController(
                viewModel: registerVM,
                coordinate: coordinate,
                placeName: placeName,
                address: address
            )
            
            vc.onRegisterCompleted = { [weak self] name, address, lat, lon in
                self?.viewModel.updateLocation(name: name, address: address, lat: lat, lon: lon)
            }
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
