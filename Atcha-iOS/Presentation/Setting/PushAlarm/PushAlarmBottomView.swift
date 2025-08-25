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
        
        volumeSlider.minimumValue = 0.1
        volumeSlider.maximumValue = 1
        volumeSlider.minimumTrackTintColor = AtchaColor.main
        volumeSlider.maximumTrackTintColor = AtchaColor.gray200
        volumeSlider.backgroundColor = .clear
        volumeSlider.isUserInteractionEnabled = true
        volumeSlider.setThumbImage(UIImage.volumeThumb, for: .normal)
        volumeSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:)))
        volumeSlider.addGestureRecognizer(tapGesture)
        
        addSubViews(soundLabelStackView, volumeSlider)
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
        AlarmManager.shared.previewAlarmVolume(sender.value)
        setVolume(sender.value)
    }
    
    @objc func sliderTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: volumeSlider)
        let percentage = point.x / volumeSlider.bounds.width
        let delta = Float(percentage) * (volumeSlider.maximumValue - volumeSlider.minimumValue)
        let newValue = volumeSlider.minimumValue + delta
        
        volumeSlider.setValue(newValue, animated: true)
        setVolume(newValue)
    }
    
    private func observeVolumeChanges() {
        volumeObservation = AVAudioSession.sharedInstance().observe(\.outputVolume, options: [.new]) { [weak self] (session, change) in
            guard let self = self, let newVolume = change.newValue else { return }
            DispatchQueue.main.async { [weak self] in
                self?.volume = newVolume
                self?.volumeSlider.value = newVolume
            }
        }
    }
    
    private func setVolume(_ volume: Float) {
        DispatchQueue.main.async {
            let volumeView = MPVolumeView()
            
            guard let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider else {
                print("UISlider를 찾을 수 없습니다.")
                return
            }
            
            let currentVolume = slider.value
            print("현재 시스템 볼륨: \(currentVolume)")
            
            if currentVolume <= 0.1 || currentVolume < volume {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    slider.value = volume
                    print("볼륨이 \(volume)으로 설정되었습니다.")
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

