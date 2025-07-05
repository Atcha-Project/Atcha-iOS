//
//  CourseStepView.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/4/25.
//

import Foundation
import UIKit
import SnapKit

final class CourseStepView: UIView {
    
    private let iconImageView: UIImageView = UIImageView()
    private let topLineImageView: UIImageView = UIImageView()
    private let bottomLineImageView: UIImageView = UIImageView()
    private let titleLabel: UILabel = UILabel()
    private let timeLabel: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Course Detail Step UI
    private func setupUI() {
        addSubview(topLineImageView)
        addSubview(bottomLineImageView)
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(timeLabel)
        
        iconImageView.contentMode = .scaleAspectFit
        
        topLineImageView.contentMode = .scaleAspectFit
        bottomLineImageView.contentMode = .scaleAspectFit
        
        topLineImageView.snp.makeConstraints { make in
            make.bottom.equalTo(iconImageView.snp.top)
            make.centerX.equalTo(iconImageView)
            make.top.equalToSuperview()
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
        }
        
        bottomLineImageView.snp.makeConstraints { make in
            make.centerX.equalTo(iconImageView)
            make.bottom.equalToSuperview()
        }
    }
    
    // MARK: - CourseStepCell Configure
    func configure(
        icon: UIImage?,
        title: String,
        time: Int?,
        showTopLine: Bool,
        showBottomLine: Bool,
        isWalk: Bool,
        isGetOff: Bool
    ) {
        iconImageView.image = icon
        titleLabel.attributedText = AtchaFont.B7_M_13(title, color: AtchaColor.white)
        
        if showTopLine {
            topLineImageView.isHidden = false
            topLineImageView.image = isWalk ? UIImage.verticalDottedLine : UIImage.verticalLine
        } else {
            topLineImageView.isHidden = true
        }
        
        if showBottomLine {
            bottomLineImageView.isHidden = false
            bottomLineImageView.image = isWalk ? UIImage.verticalDottedLine : UIImage.verticalLine
        } else {
            bottomLineImageView.isHidden = true
        }
        
        if isGetOff {
            iconImageView.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(6)
            }
            
            bottomLineImageView.snp.makeConstraints { make in
                make.top.equalTo(iconImageView.snp.bottom).offset(6)
            }
            
            titleLabel.snp.makeConstraints { make in
                make.top.equalTo(iconImageView).offset(-2)
                make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            }
            
        } else {
            iconImageView.snp.makeConstraints { make in
                make.leading.equalToSuperview()
            }
            bottomLineImageView.snp.makeConstraints { make in
                make.top.equalTo(iconImageView.snp.bottom).offset(4)
            }
            
            titleLabel.snp.makeConstraints { make in
                make.top.equalTo(iconImageView).offset(3)
                make.leading.equalTo(iconImageView.snp.trailing).offset(6)
            }
            
            if isWalk {
                timeLabel.attributedText = AtchaFont.R_12(time?.toHourMinuteString ?? "", color: AtchaColor.gray200)
                
                timeLabel.snp.makeConstraints { make in
                    make.leading.equalTo(titleLabel.snp.trailing).offset(5)
                    make.centerY.equalTo(titleLabel)
                }
            } else {
                timeLabel.attributedText = AtchaFont.R_12(time?.toHourMinuteString ?? "", color: AtchaColor.gray400)
                
                timeLabel.snp.makeConstraints { make in
                    make.top.equalTo(titleLabel.snp.bottom).offset(3)
                    make.leading.equalTo(titleLabel.snp.leading)
                }
            }
        }
    }
}
