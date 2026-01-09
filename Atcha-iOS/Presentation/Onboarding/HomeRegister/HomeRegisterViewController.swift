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
    private lazy var navigationBar: TitleNavigationBar = AtchaNavigationBar.title("우리집 설정", shouldShowCloseButton: false, onBack: { [weak self] in
        guard let self else { return }
        navigationController?.popViewController(animated: true)
    })
    private let titleLabel = UILabel()
    
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
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        if viewModel.context == .onboarding {
//            viewModel.requestAuth()
//        }
        
        AmplitudeManager.shared.trackScreen(.home_register)
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
        
        viewModel.locationStateHolder.currentLocationSubject
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self else { return }

                if self.viewModel.context == .myPage {
                    AtchaToast(message: "집 주소가 변경되었어요").show(in: self.view)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupUI(context: HomeRegisterContext) {
        switch context {
        case .onboarding:
            setupUI()
            navigationBar.isHidden = true
            
            titleLabel.snp.remakeConstraints { make in
                make.top.equalTo(navigationBar.snp.bottom)
                make.leading.equalToSuperview().inset(16)
            }
            
            searchLocationContainer.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(32)
                make.leading.trailing.equalToSuperview().inset(16)
                make.height.equalTo(50)
            }
        case .myPage:
//            viewModel.setupSelectedHome()
            nextButton.isHidden = true
            
            titleLabel.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
            
            searchLocationContainer.snp.remakeConstraints { make in
                make.top.equalTo(navigationBar.snp.bottom).offset(24)
                make.leading.trailing.equalToSuperview().inset(16)
                make.height.equalTo(50)
            }
        }
    }
    
    // MARK: - 기본 UI
    private func setupUI() {
        view.addSubViews(navigationBar,
                         titleLabel,
                         searchLocationContainer,
                         currentLocationButton,
                         nextButton)
        searchLocationContainer.addSubview(searchLocationLabel)
        titleLabel.attributedText = AtchaFont.H2_B_22("우리집 또는 귀가 장소를\n알려주세요",
                                                      color: AtchaColor.white)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 0
        searchLocationContainer.backgroundColor = AtchaColor.gray930
        searchLocationContainer.layer.cornerRadius = 10
        searchLocationContainer.isUserInteractionEnabled = true
        searchLocationLabel.attributedText = AtchaFont.B1_R_17(lineHeight: 0, "지번, 도로명, 건물명으로 검색",
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
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.equalToSuperview().inset(16)
        }
        searchLocationContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(32)
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
        
        UserDefaultsWrapper.shared.set(name, forKey: UserDefaultsWrapper.Key.buildingName.rawValue)
        UserDefaultsWrapper.shared.set(address, forKey: UserDefaultsWrapper.Key.homeAddress.rawValue)
        
        if name == "" || name == address {
            locationNameLabel.attributedText = AtchaFont.B4_R_15(address, color: AtchaColor.white)
            locationAddressLabel.isHidden = true
        } else {
            locationNameLabel.attributedText = AtchaFont.B4_R_15(name, color: AtchaColor.white)
            locationAddressLabel.attributedText = AtchaFont.B6_R_14(address, color: AtchaColor.gray200)
            locationAddressLabel.isHidden = false
        }
        
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
        AmplitudeManager.shared.track(.search_location_click)
    }
    
    // MARK: - 현위치 찾기
    @objc private func handleCurrentLocationTapped() {
        viewModel.routeHandler?(.homeRegister(useDeviceLocation: true))
        AmplitudeManager.shared.track(.current_location_click)
    }
    
    // MARK: - UI 렌더링
    private func render(_ state: LocationSelectionState) {
        searchLocationContainer.subviews.forEach {
            if $0 != searchLocationLabel { // 기본 label은 남겨둠
                $0.removeFromSuperview()
            }
        }
        currentLocationButton.removeTarget(nil, action: nil, for: .touchUpInside)
        
        switch state {
        case .none:
            // 기본 안내 label 보이게
            searchLocationLabel.isHidden = false
            setupNoneStateUI()
            currentLocationButton.addTarget(self,
                                            action: #selector(handleCurrentLocationTapped),
                                            for: .touchUpInside)
        case .selected(let name, let address):
            // 기본 안내 label은 숨김
            searchLocationLabel.isHidden = true
            setupSelectedStateUI(name: name, address: address)
            currentLocationButton.addTarget(self,
                                            action: #selector(handleSearchTapped),
                                            for: .touchUpInside)
        }
    }
}
