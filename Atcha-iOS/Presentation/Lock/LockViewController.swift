//
//  LockViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/30/25.
//

import UIKit
import SnapKit
import Lottie

final class LockViewController: BaseViewController<LockViewModel> {
    private let backgroundImageView: UIImageView = UIImageView()
    private let logoImageView: UIImageView = UIImageView()
    private let titleLabel: UILabel = UILabel()
    private let taxiFareLabel: UILabel = UILabel()
    private let startButton: AtchaButton = AtchaButton(text: "출발하기", size: .h52, style: .filled(.primary))
    private let cancelImageView: UIImageView = UIImageView()
    private let detailRouteButton: AtchaButton = AtchaButton(text: "더 늦은 경로 확인하기", size: .h52, style: .filled(.opacity))
    private let bottomStack: UIStackView = UIStackView()
    private var lottieAnimationView: LottieAnimationView = LottieAnimationView(name: "Alarm")
    private let gradientView: UIView = UIView()
    private let gradient: CAGradientLayer = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bind()
        setupUI()
        setupAutoLayout()
        observeAlarmTimeout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        lottieAnimationView.contentMode = .scaleAspectFill
        lottieAnimationView.clipsToBounds = true
        lottieAnimationView.loopMode = .loop
        lottieAnimationView.play()
        
        viewModel.refreshTaxiFare()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = gradientView.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        amp_track(.alarm_view)
    }
    
    // MARK: - ViewModel 바인딩
    private func bind() {
        viewModel.$taxiFare
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fare in
                guard let self = self else { return }
                
                if fare == 0 {
                    self.taxiFareLabel.attributedText =
                    AtchaFont.D1_EB_56("계산 중...", color: AtchaColor.Bus.widearea)
                } else {
                    self.taxiFareLabel.attributedText =
                    AtchaFont.D1_EB_56("-\(fare.formattedWithComma)", color: AtchaColor.Bus.widearea)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Lock UI
    private func setupUI() {
        view.addSubViews(backgroundImageView, lottieAnimationView, gradientView, logoImageView, titleLabel, taxiFareLabel, bottomStack, cancelImageView)
        
        backgroundImageView.image = UIImage.lockBackground
        gradient.colors = [
            UIColor.black.cgColor,
            UIColor.clear.cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientView.layer.addSublayer(gradient)
        
        logoImageView.image = UIImage.imgAtchaCharacter
        titleLabel.attributedText = AtchaFont.H2_B_22("지금 안 일어나면\n택시비", color: AtchaColor.white)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        bottomStack.addArrangedSubview(startButton)
        bottomStack.addArrangedSubview(detailRouteButton)
        bottomStack.axis = .vertical
        bottomStack.spacing = 12
        
        startButton.addTarget(self,
                              action: #selector(startTapped),
                              for: .touchUpInside)
        cancelImageView.image = UIImage.alarmCancel
        cancelImageView.isUserInteractionEnabled = true
        cancelImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelAlarmTapped)))
        
        detailRouteButton.addTarget(self,
                                    action: #selector(detailRouteTapped),
                                    for: .touchUpInside)
    }
    
    private func setupAutoLayout() {
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        lottieAnimationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        gradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(104)
            make.size.equalTo(36)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoImageView.snp.bottom).offset(28)
        }
        
        taxiFareLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
        }
        
        bottomStack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(32)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().inset(20)
        }
        
        cancelImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(18)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(24)
        }
    }
    
    @objc private func startTapped() {
        viewModel.cancelLockScreenTimer()
        AlarmManager.shared.stopAlarm()
        AlarmManager.shared.removeAllAlarmNotificationsExceptAutoStop()
        
        let wrapper = UserDefaultsWrapper.shared
        let legInfo = wrapper.object(forKey: UserDefaultsWrapper.Key.legInfo.rawValue, of: LegInfo.self)
        let addressDesc = wrapper.string(forKey: UserDefaultsWrapper.Key.addressDesc.rawValue) ?? ""
        viewModel.routerHandler?(.lockScreen(info: legInfo, address: addressDesc))
        
        UserDefaultsWrapper.shared.set(
            true,
            forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue
        )
        
        amp_track(.start_click)
    }
    
    @objc private func detailRouteTapped() {
        
        AlarmManager.shared.stopAlarm()
        
        let wrapper = UserDefaultsWrapper.shared
        let lat = wrapper.string(forKey: UserDefaultsWrapper.Key.startLat.rawValue) ?? ""
        let lon = wrapper.string(forKey: UserDefaultsWrapper.Key.startLon.rawValue) ?? ""
        let address = wrapper.string(forKey: UserDefaultsWrapper.Key.startAddress.rawValue) ?? ""
        
        amp_track(.later_course_click)
        viewModel.routerHandler?(.courseSearch(startLat: lat, startLon: lon, startAddress: address, context: .afterReigster))
        
        UserDefaultsWrapper.shared.set(
            true,
            forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue
        )
    }
    
    @objc private func cancelAlarmTapped() {
        showAlarmCancelPopup()
    }
    
    private func observeAlarmTimeout() {
        NotificationCenter.default.publisher(for: NSNotification.Name("alarmDidTimeout"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                // 수정됨: 화면을 닫고 메인으로 돌아가는 올바른 라우터 명령 전달
                self?.viewModel.routerHandler?(.dismissLockScreen)
            }
            .store(in: &cancellables)
    }
    
    private func showAlarmCancelPopup() {
        AlarmManager.shared.stopAlarm()
        
        let popupVM = AtchaPopupViewModel(info: .alarm_cancel)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.cancelButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: false)
        }, for: .touchUpInside)
        
        popupVC.confirmButton.addAction(UIAction { [weak self, weak popupVC] _ in
            guard let self else { return }
            popupVC?.dismiss(animated: false)
            
            self.viewModel.cancelLockScreenTimer()
            AlarmManager.shared.stopAlarm()
            AlarmManager.shared.removeAllAlarmNotificationsExceptAutoStop()
            
            UserDefaultsWrapper.shared.set(
                false,
                forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue
            )
            
            viewModel.routerHandler?(.dismissLockScreen)
        }, for: .touchUpInside)
        
        popupVC.modalPresentationStyle = .overFullScreen
        present(popupVC, animated: false)
    }
}
