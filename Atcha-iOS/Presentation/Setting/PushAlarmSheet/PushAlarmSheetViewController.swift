//
//  PushAlarmSheetViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 3/4/26.
//

import UIKit
import SnapKit
import QuartzCore
import AVFAudio
import MediaPlayer

final class PushAlarmSheetViewController: BaseViewController<PushAlarmSheetViewModel> {
    
    // MARK: - UI Components
    private let dimView = UIView()
    private let containerView = UIView()
    private let sheetHeight: CGFloat = 430
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.attributedText = AtchaFont.H2_B_22(lineHeight: 0, "알람 받을 방법을\n설정해 주세요")
        label.textColor = AtchaColor.white
        label.numberOfLines = 2
        return label
    }()
    
    private let closeImageView: UIImageView = {
        let image = UIImageView()
        image.image = .xGray
        image.tintColor = AtchaColor.gray100
        return image
    }()
    
    private let alarmListStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()
    
    private lazy var completeButton: AtchaButton = AtchaButton(
        text: "완료",
        size: .h52,
        style: .filled(.primary)
    )
    
    // MARK: - Properties
    private var alarmCheckmarkLists: [AtchaList] = []
    private var selectedOption: PushAlarmOption?
    
    // 화면이 닫혔을 때 코디네이터나 부모에게 알리기 위한 콜백
    var onDismiss: (() -> Void)?
    var onComplete: (() -> Void)? // 완료 버튼 눌렀을 때만 호출
    private var isConfirmed: Bool = false
    
    private let volumeSlider: AtchaSlider = AtchaSlider()
    private var volumeObservation: NSKeyValueObservation?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        
        setupDim()
        setupUI()
        setupAutoLayout()
        setupAlarmLists()
        setupGestures()
        observeVolumeChanges()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.dimView.alpha = 1
            self.containerView.transform = .identity
        }) { _ in
            AlarmManager.shared.previewAlarmVolume(0.3)
        }
        volumeSlider.isHidden = true
    }
    
    deinit {
        AlarmManager.shared.stopPreview()
        volumeObservation?.invalidate()
    }
    
    // MARK: - Setup Methods
    private func setupDim() {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        dimView.alpha = 0
        view.addSubview(dimView)
    }
    
    private func setupUI() {
        containerView.backgroundColor = .gray950
        containerView.layer.cornerRadius = 24
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        
        view.backgroundColor = .clear
        containerView.addSubViews(titleLabel, closeImageView, alarmListStackView, completeButton, volumeSlider)
        
        // 버튼 타겟 설정
        closeImageView.isUserInteractionEnabled = true
        
        let closeTap = UITapGestureRecognizer(target: self, action: #selector(didTapCloseButton))
        closeImageView.addGestureRecognizer(closeTap)
        completeButton.addTarget(self, action: #selector(didTapCompleteButton), for: .touchUpInside)
        
        // 초기 상태: 화면 아래에 숨김
        containerView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        
        volumeSlider.minimumValue = 1 / 16
        volumeSlider.maximumValue = 1.0
        volumeSlider.minimumTrackTintColor = AtchaColor.white
        volumeSlider.maximumTrackTintColor = AtchaColor.gray910
        volumeSlider.backgroundColor = .clear
        volumeSlider.isUserInteractionEnabled = true
        volumeSlider.isContinuous = false
        volumeSlider.setThumbImage(UIImage.volumeThumb, for: .normal)
        volumeSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:)))
        volumeSlider.addGestureRecognizer(tapGesture)
        volumeSlider.setValue(0.3, animated: true)
    }
    
    private func setupAutoLayout() {
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(sheetHeight)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().inset(24)
        }
        
        closeImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().inset(24)
            make.width.height.equalTo(24)
        }
        
        alarmListStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview()
        }
        
        
        volumeSlider.snp.makeConstraints { make in
            make.top.equalTo(alarmListStackView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(20)
        }
        
        completeButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(40)
        }
    }
    
    private func setupAlarmLists() {
        // 이미지 순서: 소리 및 진동, 소리, 진동
        let options: [PushAlarmOption] = [.both, .onlySound, .onlyVibration]
        
        // 기본 선택값을 .both로 강제 설정
        let currentOption = PushAlarmOption.onlyVibration
        self.selectedOption = currentOption
        AlarmManager.shared.setAlarmOption(currentOption)
        
        options.forEach { option in
            let isSelected = (option == currentOption)
            let listView = AtchaList(
                title: option.rawValue,
                listType: .radioButton(isOn: isSelected)
            )
            
            listView.backgroundColor = isSelected ? AtchaColor.opacity100 : .clear
            
            listView.onSelect = { [weak self] selected in
                guard let self = self else { return }
                
                self.alarmCheckmarkLists.forEach {
                    $0.setRadio(false)
                    $0.backgroundColor = .clear
                }
                selected.setRadio(true)
                selected.backgroundColor = AtchaColor.opacity100
                self.selectedOption = option
                
                self.updateVolumeSliderVisibility(for: option)
                // 매니저의 옵션을 먼저 변경한 뒤 미리보기 호출
                AlarmManager.shared.setAlarmOption(option)
                if option != .onlyVibration {
                    AlarmManager.shared.previewAlarmVolume(self.volumeSlider.value)
                } else {
                    AlarmManager.shared.stopPreview()
                }
            }
            
            listView.snp.makeConstraints { $0.height.equalTo(52) }
            alarmListStackView.addArrangedSubview(listView)
            alarmCheckmarkLists.append(listView)
        }
    }
}

// MARK: - Actions
extension PushAlarmSheetViewController {
    
    // X 버튼 클릭 시 실행
    @objc private func didTapCloseButton() {
        AlarmManager.shared.stopPreview()
        isConfirmed = false
        dismissSheet()
    }
    
    // 완료 버튼 클릭 시 실행
    @objc private func didTapCompleteButton() {
        if let option = selectedOption {
            AlarmManager.shared.stopPreview()
            AlarmManager.shared.setAlarmOption(option)
            AlarmManager.shared.setAlarmArmed(true)
            isConfirmed = true
            
            amp_track(
                .alarm_alert_type_setting, properties:
                props(
                    AmplitudeProperty.alertType(self.mapAlertType(option))
                )
            )
        }
        
        dismissSheet()
    }
    
    private func mapAlertType(_ option: PushAlarmOption) -> AlertType {
        switch option {
        case .onlyVibration: return .onlyVibration
        case .onlySound:     return .onlySound
        case .both:          return .soundAndVibration
        }
    }
    
    @objc private func sliderChanged(_ sender: UISlider) {
        let clampedValue = max(sender.value, 0.1)
        sender.setValue(clampedValue, animated: false)
        
        AlarmManager.shared.previewAlarmVolume(clampedValue)
        AlarmManager.shared.setAlarmVolume(clampedValue)
        setVolume(clampedValue)
    }
    
    @objc func sliderTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: volumeSlider)
        let percentage = point.x / volumeSlider.bounds.width
        let delta = Float(percentage) * (volumeSlider.maximumValue - volumeSlider.minimumValue)
        var newValue = volumeSlider.minimumValue + delta
        
        newValue = max(newValue, 0.1)
        volumeSlider.setValue(newValue, animated: true)
        AlarmManager.shared.setAlarmVolume(newValue)
        setVolume(newValue)
    }
    
    private func setVolume(_ volume: Float) {
        let clampedVolume = max(volume, 0.1) // 최소 볼륨 제한
        
        DispatchQueue.main.async {
            let volumeView = MPVolumeView()
            
            guard let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider else {
                print("UISlider를 찾을 수 없습니다.")
                return
            }
            
            let currentVolume = slider.value
            print("현재 시스템 볼륨: \(currentVolume)")
            
            if currentVolume <= 0.1 || currentVolume < clampedVolume {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    slider.value = clampedVolume
                    print("볼륨이 \(clampedVolume)으로 설정되었습니다.")
                }
            } else {
                print("현재 볼륨이 설정하려는 값보다 높아 변경하지 않습니다.")
            }
        }
    }
    
    private func observeVolumeChanges() {
        volumeObservation = AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.new]) { [weak self] (session, change) in
            guard let self = self, let newVolume = change.newValue else { return }
            DispatchQueue.main.async { [weak self] in
                let clamped = max(newVolume, 0.1)
                self?.volumeSlider.value = clamped
                self?.setVolume(clamped)
            }
        }
    }
    
    private func updateVolumeSliderVisibility(for option: PushAlarmOption) {
        // 소리가 포함된 옵션(.both, .onlySound)일 때만 true
        let isSoundEnabled = (option == .both || option == .onlySound)
        
        UIView.animate(withDuration: 0.2) {
            self.volumeSlider.isHidden = !isSoundEnabled
            self.volumeSlider.alpha = isSoundEnabled ? 1 : 0
        }
    }
}

// MARK: - Gestures & Animations
extension PushAlarmSheetViewController {
    private func setupGestures() {
        // 배경 터치 시 닫기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapDimView))
        dimView.addGestureRecognizer(tapGesture)
        dimView.isUserInteractionEnabled = true
        
        // 스와이프해서 닫기
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    @objc private func didTapDimView() {
        AlarmManager.shared.stopPreview()
        dismissSheet()
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled:
            if velocity.y > 1000 || translation.y > (sheetHeight / 2) {
                AlarmManager.shared.stopPreview()
                dismissSheet()
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                    self.containerView.transform = .identity
                })
            }
        default: break
        }
    }
    
    // 닫기 애니메이션 공통 로직
    private func dismissSheet() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.dimView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
        }) { _ in
            self.dismiss(animated: false) {
                if self.isConfirmed {
                    self.onComplete?()
                }
                self.onDismiss?()
            }
        }
    }
}
