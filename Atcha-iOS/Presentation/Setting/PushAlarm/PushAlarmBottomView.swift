//
//  PushAlarmBottomView.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/19/25.
//

import Foundation
import UIKit
import AVFAudio

final class PushAlarmBottomView: UIView {
    
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
        loadInitialVolume()
    }
    
    var currentVolume: Float {
            return volumeSlider.value
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Setting
    private func setupView() {
        backgroundColor = AtchaColor.gray940
        layer.cornerRadius = 20
        
        volumeTitleLabel.attributedText = AtchaFont.H4_SB_17("소리 크기", color: AtchaColor.white)
        volumeSubTitleLabel.attributedText = AtchaFont.B6_R_14("설정한 크기로 알람이 울려요", color: AtchaColor.gray200)
        
        volumeSlider.minimumValue = 0.1
        volumeSlider.maximumValue = 1
        volumeSlider.minimumTrackTintColor = AtchaColor.main
        volumeSlider.maximumTrackTintColor = AtchaColor.gray200
        volumeSlider.backgroundColor = .clear
        volumeSlider.setThumbImage(UIImage.volumeThumb, for: .normal)
        volumeSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        
        
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
        let volume = sender.value
        AlarmManager.shared.previewAlarmVolume(volume)
    }
    
    private func loadInitialVolume() {
        volumeSlider.value = AlarmManager.shared.currentVolume
    }
}
