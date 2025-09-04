//
//  CourseStepView.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/4/25.
//

import Foundation
import UIKit
import SnapKit

enum LineStyle {
    case none
    case solid
    case dotted
}

final class CourseStepView: UIView {
    
    private let iconImageView: UIImageView = UIImageView()
    private let topLineImageView: UIImageView = UIImageView()
    private let bottomLineImageView: UIImageView = UIImageView()
    private let titleLabel: UILabel = UILabel()
    private let timeLabel: UILabel = UILabel()
    private let arriveTimeLabel: UILabel = UILabel()
    
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
        addSubview(arriveTimeLabel)
        
        iconImageView.contentMode = .scaleAspectFit
        topLineImageView.contentMode = .scaleAspectFit
        bottomLineImageView.contentMode = .scaleAspectFit
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
        }
        
        topLineImageView.snp.makeConstraints { make in
            make.centerX.equalTo(iconImageView)
            make.bottom.equalTo(iconImageView.snp.top)
            make.top.greaterThanOrEqualToSuperview()
        }
        
        bottomLineImageView.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom)
            make.centerX.equalTo(iconImageView)
            make.height.equalTo(18)
            make.bottom.equalToSuperview().priority(.medium)
        }
    }
    
    // MARK: - CourseStepCell Configure
    func configure(
        icon: UIImage?,
        title: String,
        time: Int?,
        topLineStyle: LineStyle,
        bottomLineStyle: LineStyle,
        isGetOff: Bool,
        arriveTime: String?
    ) {
        iconImageView.image = icon
        titleLabel.attributedText = AtchaFont.B7_M_13(title, color: AtchaColor.white)
        
        switch topLineStyle {
        case .none:
            topLineImageView.isHidden = true
            topLineImageView.snp.remakeConstraints { make in
                make.centerX.equalTo(iconImageView)
                make.bottom.equalTo(iconImageView.snp.top)
                make.top.greaterThanOrEqualToSuperview()
                make.height.equalTo(0)
            }
        case .solid:
            topLineImageView.isHidden = false
            topLineImageView.image = UIImage.verticalLine
            topLineImageView.snp.remakeConstraints { make in
                make.centerX.equalTo(iconImageView)
                make.bottom.equalTo(iconImageView.snp.top)
                make.top.greaterThanOrEqualToSuperview()
                make.height.equalTo(18)
            }
        case .dotted:
            topLineImageView.isHidden = false
            topLineImageView.image = UIImage.verticalDottedLine
            topLineImageView.snp.remakeConstraints { make in
                make.centerX.equalTo(iconImageView)
                make.bottom.equalTo(iconImageView.snp.top)
                make.top.greaterThanOrEqualToSuperview()
                make.height.equalTo(18)
            }
        }
        
        switch bottomLineStyle {
        case .none:
            bottomLineImageView.isHidden = true
            bottomLineImageView.snp.remakeConstraints { make in
                make.top.equalTo(iconImageView.snp.bottom).offset(isGetOff ? 6 : 4)
                make.centerX.equalTo(iconImageView)
                make.height.equalTo(0)
                make.bottom.equalToSuperview().priority(.medium)
            }
        case .solid:
            bottomLineImageView.isHidden = false
            bottomLineImageView.image = UIImage.verticalLine
            bottomLineImageView.snp.remakeConstraints { make in
                make.top.equalTo(iconImageView.snp.bottom).offset(isGetOff ? 6 : 4)
                make.centerX.equalTo(iconImageView)
                make.height.equalTo(18)
                make.bottom.equalToSuperview().priority(.medium)
            }
        case .dotted:
            bottomLineImageView.isHidden = false
            bottomLineImageView.image = UIImage.verticalDottedLine
            bottomLineImageView.snp.remakeConstraints { make in
                make.top.equalTo(iconImageView.snp.bottom).offset(isGetOff ? 6 : 4)
                make.centerX.equalTo(iconImageView)
                make.height.equalTo(18)
                make.bottom.equalToSuperview().priority(.medium)
            }
        }
        
        iconImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(isGetOff ? 6 : 0)
        }
        
//        bottomLineImageView.snp.remakeConstraints { make in
//            make.top.equalTo(iconImageView.snp.bottom).offset(isGetOff ? 6 : 4)
//            make.centerX.equalTo(iconImageView)
//            make.height.equalTo(18)
//            make.bottom.equalToSuperview().priority(.medium)
//        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView).offset(isGetOff ? -2 : 3)
            make.leading.equalTo(iconImageView.snp.trailing).offset(isGetOff ? 12 : 6)
        }
        
        if let t = time {
            timeLabel.isHidden = false
            
            if title.contains("걷기") {
                timeLabel.attributedText = AtchaFont.R_12(t.toHourMinuteStringFromSeconds, color: AtchaColor.gray200)
                
                timeLabel.snp.remakeConstraints { make in
                    make.leading.equalTo(titleLabel.snp.trailing).offset(5)
                    make.centerY.equalTo(titleLabel)
                }
            } else {
                timeLabel.attributedText = AtchaFont.R_12(t.toHourMinuteStringFromSeconds, color: AtchaColor.gray400)
                
                timeLabel.snp.remakeConstraints { make in
                    make.top.equalTo(titleLabel.snp.bottom).offset(5)
                    make.leading.equalTo(titleLabel.snp.leading)
                }
            }
        } else {
            timeLabel.isHidden = true
            timeLabel.snp.remakeConstraints { make in
                make.height.equalTo(0) // 숨겨졌을 때의 제약
            }
        }
        
        if let t = arriveTime {
            
            arriveTimeLabel.isHidden = false
            arriveTimeLabel.attributedText = AtchaFont.R_12("\(t) 도착 예정", color: AtchaColor.gray400)
            
            arriveTimeLabel.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(5)
                make.leading.equalTo(titleLabel.snp.leading)
            }
        } else {
            arriveTimeLabel.isHidden = true
            arriveTimeLabel.snp.remakeConstraints { make in
                make.height.equalTo(0) // 숨겨졌을 때의 제약
            }
        }
    }
}


