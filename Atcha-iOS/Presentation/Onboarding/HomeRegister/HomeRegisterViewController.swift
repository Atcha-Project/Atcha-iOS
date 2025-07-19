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
    private lazy var titleStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        return stack
    }()
    
    private let searchLocationContainer = UIView()
    private let searchLocationLabel = UILabel()
    
    private let locationNameLabel = UILabel()
    private let locationAddressLabel = UILabel()
    
    private let currentLocationButton = UIButton()
    private lazy var nextButton = AtchaButton(text: "다음", size: .h52, style: .filled(.disabled)) { [weak self] in
        self?.viewModel.routeHandler?(.pushRegister)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupAutoLayout()
        addGesture()
    }
    
    // MARK: - ViewModel 바인딩
    private func bindViewModel() {
        viewModel.routeHandler?(.permission)
        
        viewModel.$selectedState
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
        
        viewModel.$context
            .receive(on: RunLoop.main)
            .sink { [weak self] context in
                guard let self else { return }
                setupUI(context: context)
            }
            .store(in: &cancellables)
    }
    
    private func setupUI(context: HomeRegisterContext) {
        switch context {
        case .onboarding:
            view.backgroundColor = .red
        case .myPage:
            view.backgroundColor = .blue
        }
    }
    
    // MARK: - 기본 UI
    private func setupUI() {
        view.addSubViews(titleStackView,
                         searchLocationContainer,
                         currentLocationButton,
                         nextButton)
        searchLocationContainer.addSubview(searchLocationLabel)
        titleLabel.attributedText = AtchaFont.H2_B_22("우리 집을 등록해 보세요",
                                                      color: AtchaColor.white)
        subTitleLabel.attributedText = AtchaFont.B4_R_15("출발지에서 우리집까지 빠르게 막차 찾을 수 있어요.",
                                                         color: AtchaColor.gray200)
        searchLocationContainer.backgroundColor = AtchaColor.gray930
        searchLocationContainer.layer.cornerRadius = 10
        searchLocationContainer.isUserInteractionEnabled = true
        searchLocationLabel.attributedText = AtchaFont.B1_R_17("지번, 도로명, 건물명으로 검색",
                                                               color: AtchaColor.gray400)
        
        currentLocationButton.backgroundColor = .clear
        currentLocationButton.layer.cornerRadius = 8
        currentLocationButton.layer.borderWidth = 1
        currentLocationButton.layer.borderColor = AtchaColor.gray800.cgColor
        currentLocationButton.tintColor = .white
        setupLocationButton(title: "현위치 찾기", icon: UIImage.mylocationOutlined)
        
        nextButton.isEnabled = false
        nextButton.updateStyle(text: "다음", style: .filled(.disabled))
    }
    
    private func setupAutoLayout() {
        titleStackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).inset(72)
            make.leading.equalToSuperview().inset(16)
        }
        searchLocationContainer.snp.makeConstraints { make in
            make.top.equalTo(titleStackView.snp.bottom).offset(48)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
        currentLocationButton.snp.makeConstraints { make in
            make.top.equalTo(searchLocationContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        searchLocationLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        nextButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
    }
    
    private func addGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSearchTapped))
        searchLocationContainer.addGestureRecognizer(tapGesture)
        currentLocationButton.addTarget(self, action: #selector(handleCurrentLocationTapped), for: .touchUpInside)
    }
    
    // MARK: - 장소 미선택 UI
    private func setupNoneStateUI() {
        setupLocationButton(title: "현위치 찾기", icon: UIImage.mylocationOutlined)
    }
    
    // MARK: - 장소 선택 UI
    private func setupSelectedStateUI(name: String, address: String) {
        searchLocationContainer.backgroundColor = .clear
        locationNameLabel.attributedText = AtchaFont.B2_SB_15(name, color: AtchaColor.white)
        locationAddressLabel.attributedText = AtchaFont.B6_R_14(address, color: AtchaColor.gray200)
        
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
    private func setupLocationButton(title: String,
                                     icon: UIImage?) {
        currentLocationButton.setAttributedTitle(AtchaFont.B4_R_15(title, color: .white), for: .normal)
        currentLocationButton.setImage(icon, for: .normal)
        currentLocationButton.imageView?.contentMode = .scaleAspectFit
        currentLocationButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 10, right: 6)
    }
    
    // MARK: - 장소 검색
    @objc private func handleSearchTapped() {
        viewModel.routeHandler?(.searchAdress)
    }
    
    // MARK: - 현위치 찾기
    @objc private func handleCurrentLocationTapped() {
        viewModel.routeHandler?(.homeRegister)
    }
    
    // MARK: - UI 렌더링
    private func render(_ state: LocationSelectionState) {
        searchLocationContainer.subviews.forEach { $0.removeFromSuperview() }
        currentLocationButton.removeTarget(nil, action: nil, for: .touchUpInside)
        
        switch state {
        case .none:
            setupNoneStateUI()
            currentLocationButton.addTarget(self, action: #selector(handleCurrentLocationTapped), for: .touchUpInside)
        case .selected(let name, let address):
            setupSelectedStateUI(name: name, address: address)
            currentLocationButton.addTarget(self, action: #selector(handleSearchTapped), for: .touchUpInside)
        }
    }
}
