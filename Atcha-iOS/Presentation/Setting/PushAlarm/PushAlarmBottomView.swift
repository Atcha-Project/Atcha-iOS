//
//  PushAlarmBottomView.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/19/25.
//

import Foundation
import UIKit
import AVFAudio
import MediaPlayer

final class PushAlarmBottomView: UIView {
    private var currentVolume: Float = AVAudioSession.sharedInstance().outputVolume
    private var volumeObservation: NSKeyValueObservation?
    private var volume: Float = 0.7
    
    private let volumeTitleLabel: UILabel = UILabel()
    private let volumeSubTitleLabel: UILabel = UILabel()
    
    private lazy var soundLabelStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [volumeTitleLabel, volumeSubTitleLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }()
    
    private let volumeSlider = UISlider()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
        setupAutoLayout()
        observeVolumeChanges()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Setting
    private func setupView() {
        backgroundColor = AtchaColor.gray940
        layer.cornerRadius = 20
        addSubViews(soundLabelStackView, volumeSlider)
        
        volumeTitleLabel.attributedText = AtchaFont.H4_SB_17("소리 크기", color: AtchaColor.white)
        volumeSubTitleLabel.attributedText = AtchaFont.B6_R_14("설정한 크기로 알람이 울려요", color: AtchaColor.gray200)
        
        volumeSlider.minimumValue = 1 / 16
        volumeSlider.maximumValue = 1.0
        volumeSlider.minimumTrackTintColor = AtchaColor.main
        volumeSlider.maximumTrackTintColor = AtchaColor.gray200
        volumeSlider.backgroundColor = .clear
        volumeSlider.isUserInteractionEnabled = true
        volumeSlider.isContinuous = false
        volumeSlider.setThumbImage(UIImage.volumeThumb, for: .normal)
        volumeSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:)))
        volumeSlider.addGestureRecognizer(tapGesture)
        volumeSlider.setValue(0.7, animated: true)
        
        let savedVolume = UserDefaultsWrapper.shared.float(
                forKey: UserDefaultsWrapper.Key.alarmVolume.rawValue
            ) ?? 0.7
            
            volumeSlider.setValue(savedVolume, animated: false)
        
        addSubViews(soundLabelStackView, volumeSlider)
        setVolume(savedVolume)
    }
    
    private func setupAutoLayout() {
        soundLabelStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(32)
            make.leading.equalToSuperview().offset(16)
        }
        
        volumeSlider.snp.makeConstraints { make in
            make.top.equalTo(soundLabelStackView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(20)
            make.bottom.lessThanOrEqualToSuperview().inset(92)
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
    
    func getVolume() -> Float {
        return volumeSlider.value
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
    
    deinit {
        volumeObservation?.invalidate()
    }
}

