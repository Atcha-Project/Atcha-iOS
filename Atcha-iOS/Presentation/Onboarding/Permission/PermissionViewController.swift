//
//  PermissionViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/15/25.
//

import UIKit

final class PermissionViewController: BaseViewController<PermissionViewModel> {
    private let dimView = UIView()
    private let containerView = UIView()
    private let sheetHeight: CGFloat = 340
    
    private let titleLabel: UILabel = UILabel()
    
    private let locationIconImageVIew: UIImageView = UIImageView()
    private let locationIconContainer: UIView = UIView()
    private let locationTitleLabel: UILabel = UILabel()
    private let locationDescLabel: UILabel = UILabel()
    
    private lazy var locationTextStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [locationTitleLabel, locationDescLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        return stackView
    }()
    
    private lazy var locationSectionStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [locationIconContainer, locationTextStackView])
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .top
        return stackView
    }()
    
    private let alarmIconImageView: UIImageView = UIImageView()
    private let alarmIconContainer: UIView = UIView()
    private let alarmTitleLabel: UILabel = UILabel()
    private let alarmDescLabel: UILabel = UILabel()
    
    private lazy var alarmTextStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [alarmTitleLabel, alarmDescLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        return stackView
    }()
    
    private lazy var alarmSectionStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [alarmIconContainer, alarmTextStackView])
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .top
        return stackView
    }()
    
    private lazy var infoStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [locationSectionStackView, alarmSectionStackView])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        return stackView
    }()
    
    private let button: AtchaButton = AtchaButton(text: "허용하기", size: .h48, style: .filled(.primary))
    
    // 설정 앱 다녀온 뒤 바로 이어서 실행하기 위한 플래그들
    private var shouldRequestPushOnBecomeActive: Bool = false
    private var shouldFinishAfterPushSettings: Bool = false
    private var didBecomeActiveToken: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDim()
        setupContainer()
        
        setupUI()
        setupAutoLayout()
        setupGesture()
        bindViewModel()
        observeDidBecomeActive()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dimView.alpha = 1
    }
    
    private func setupDim() {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        dimView.alpha = 0
        view.addSubview(dimView)
    }
    
    private func setupContainer() {
        containerView.backgroundColor = .gray940
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        view.addSubview(containerView)
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        containerView.addSubViews(titleLabel, infoStackView, button)
        
        titleLabel.attributedText = AtchaFont.H3_B_20("막차 안내를 위해\n꼭 필요한 권한만 받아요", color: .white)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .left
        
        locationIconImageVIew.image = UIImage.placeOutlined
        locationIconImageVIew.tintColor = .white
        locationIconContainer.addSubview(locationIconImageVIew)
        
        alarmIconImageView.image = UIImage.bellFilled
        alarmIconImageView.tintColor = .white
        alarmIconContainer.addSubview(alarmIconImageView)
        
        locationTitleLabel.attributedText = AtchaFont.B5_SB_14(lineHeight: 0, "위치", color: .white)
        locationDescLabel.attributedText = AtchaFont.B6_R_14("현위치를 기준으로 빠르게 막차를 찾아요", color: .gray200)
        
        alarmTitleLabel.attributedText = AtchaFont.B5_SB_14(lineHeight: 0, "알람", color: .white)
        alarmDescLabel.attributedText = AtchaFont.B6_R_14("제시간에 막차를 탈 수 있게 알람을 드려요", color: .gray200)
    }
    
    private func setupAutoLayout() {
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(sheetHeight)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView.safeAreaLayoutGuide).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        locationIconImageVIew.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(1)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        locationIconContainer.snp.makeConstraints { make in
            make.height.equalTo(17)
            make.width.equalTo(16)
        }
        
        alarmIconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(1)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        alarmIconContainer.snp.makeConstraints { make in
            make.height.equalTo(17)
            make.width.equalTo(16)
        }
        
        infoStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-40)
        }
    }
    
    private func setupGesture() {
        button.addTarget(self, action: #selector(handleRegiTap), for: .touchUpInside)
    }
    
    private func bindViewModel() {
        viewModel.$checkPermissionFinished
            .filter { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)
        
        viewModel.$showLocationDeniedAlert
            .filter { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.presentLocationDeniedAlert()
            }
            .store(in: &cancellables)
        
        viewModel.$showPushDeniedAlert
            .filter { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.presentPushDeniedAlert()
            }
            .store(in: &cancellables)
    }
    
    private func presentLocationDeniedAlert() {
        let alert = UIAlertController(
            title: nil,
            message: "위치 권한을 허용하지 않으면\n현위치의 막차를 확인할 수 없어요.",
            preferredStyle: .alert
        )
        
        // 닫기: Alert 닫힌 다음 바로 알림 권한 요청
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel) { [weak self] _ in
            // 다음 runloop에 태워서(터치 해야 뜨는 현상 방지)
            DispatchQueue.main.async {
                self?.viewModel.continueToPushPermission()
            }
        })
        
        // 설정하기: 설정 앱 갔다가 돌아오면 didBecomeActive에서 알림 권한 요청
        alert.addAction(UIAlertAction(title: "설정하기", style: .default) { [weak self] _ in
            guard let self else { return }
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            self.shouldRequestPushOnBecomeActive = true
            UIApplication.shared.open(url)
        })
        
        present(alert, animated: true)
    }
    
    private func presentPushDeniedAlert() {
        let alert = UIAlertController(
            title: nil,
            message: "알림을 허용하지 않으면\n막차 알람이 울리지 못해요.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel) { [weak self] _ in
            self?.viewModel.continueAfterPushDeniedAlertDismiss()
        })
        
        alert.addAction(UIAlertAction(title: "설정하기", style: .default) { [weak self] _ in
            guard let self else { return }
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            self.shouldFinishAfterPushSettings = true
            UIApplication.shared.open(url)
        })
        
        present(alert, animated: true)
    }
    
    private func observeDidBecomeActive() {
        guard didBecomeActiveToken == nil else { return }
        
        didBecomeActiveToken = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            
            if self.shouldRequestPushOnBecomeActive {
                self.shouldRequestPushOnBecomeActive = false
                // 복귀 직후 바로 뜨게(터치 필요 현상 방지)
                DispatchQueue.main.async {
                    self.viewModel.continueToPushPermission()
                }
                return
            }
            
            if self.shouldFinishAfterPushSettings {
                self.shouldFinishAfterPushSettings = false
                DispatchQueue.main.async {
                    self.viewModel.continueAfterPushDeniedAlertFromSettings()
                }
                return
            }
        }
    }
    
    deinit {
        if let didBecomeActiveToken {
            NotificationCenter.default.removeObserver(didBecomeActiveToken)
        }
    }
}

extension PermissionViewController {
    @objc private func handleRegiTap() {
        dimView.alpha = 0
        dismiss(animated: true)
        viewModel.startPermissionFlow()
        AmplitudeManager.shared.track(.permission_setting)
        AmplitudeManager.shared.timerStart("signup_dwell")
    }
}
