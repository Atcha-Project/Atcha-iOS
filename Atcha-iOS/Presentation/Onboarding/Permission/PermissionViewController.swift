//
//  PermissionViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/15/25.
//

import UIKit
import PanModal

final class PermissionViewController: BaseViewController<PermissionViewModel> {
    private let titleLabel: UILabel = UILabel()
    
    private let locationIconImageVIew: UIImageView = UIImageView()
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
        let stackView = UIStackView(arrangedSubviews: [locationIconImageVIew, locationTextStackView])
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .top
        return stackView
    }()
    
    private let alarmIconImageView: UIImageView = UIImageView()
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
        let stackView = UIStackView(arrangedSubviews: [alarmIconImageView, alarmTextStackView])
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        setupGesture()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = .gray940
        view.addSubViews(titleLabel, infoStackView, button)
        
        titleLabel.attributedText = AtchaFont.H3_B_20("막차 안내를 위해\n꼭 필요한 권한만 받아요", color: .white)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .left
        
        locationIconImageVIew.image = UIImage.placeOutlined
        locationIconImageVIew.tintColor = .white
        alarmIconImageView.image = UIImage.bellFilled
        alarmIconImageView.tintColor = .white
        
        locationTitleLabel.attributedText = AtchaFont.B5_SB_14("위치", color: .white)
        locationDescLabel.attributedText = AtchaFont.B6_R_14("현위치를 기준으로 빠르게 막차를 찾아요", color: .gray200)
        alarmTitleLabel.attributedText = AtchaFont.B5_SB_14("알림", color: .white)
        alarmDescLabel.attributedText = AtchaFont.B6_R_14("제시간에 막차를 탈 수 있게 알림을 드려요", color: .gray200)
    }
    
    private func setupAutoLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(32)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        locationIconImageVIew.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        
        alarmIconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
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
        button.addTarget(self,
                         action: #selector(handleRegiTap),
                         for: .touchUpInside)
    }
    
    private func bindViewModel() {
//        viewModel.$deniedAlert
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                let alert = AlertFactory.makeSettingsAlert(
//                    title: "알림 권한 필요",
//                    message: "알림을 허용하지 않으면 막차 알람이 울리지 못해요.",
//                    cancelTitle: "닫기",
//                    confirmTitle: "설정 가기"
//                ) {
//                    if let settingsURL = URL(string: UIApplication.openSettingsURLString),
//                       UIApplication.shared.canOpenURL(settingsURL) {
//                        UIApplication.shared.open(settingsURL)
//                    }
//                }
//                
//                self?.present(alert, animated: true)
//            }
//            .store(in: &cancellables)
    }
}

extension PermissionViewController {
    @objc private func handleRegiTap() {
        viewModel.askLocationPermission()
    }
}

extension PermissionViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }
    
    var showDragIndicator: Bool {
        return false
    }
    
    var cornerRadius: CGFloat {
        return 20
    }
    
    var shortFormHeight: PanModalHeight {
        return .contentHeight(308)
    }
    
    // 확장 가능 높이: longFormHeight
    var longFormHeight: PanModalHeight {
        return .contentHeight(308)
    }
}


//private func observeAppDidBecomeActive() {
//    NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
//        .sink { [weak self] _ in
//            UNUserNotificationCenter.current().getNotificationSettings { settings in
//                DispatchQueue.main.async {
//                    print("🔔 현재 알림 권한 상태: \(settings.authorizationStatus)")
//                    
//                    // 예: 허용됐으면 UI 상태 갱신
////                        if settings.authorizationStatus == .authorized {
////                            self?.viewModel.askPushPermission()
////                        }
//                }
//            }
//        }
//        .store(in: &cancellables)
//}
