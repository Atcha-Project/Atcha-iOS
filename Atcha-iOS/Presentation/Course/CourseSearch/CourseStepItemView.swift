//
//  CourseStepItemView.swift
//  Atcha-iOS
//
//  Created by wodnd on 1/14/26.
//

import Foundation
import UIKit
import SnapKit

final class CourseStepItemView: UIView {
    private let trafficImageView: UIImageView = UIImageView()
    private let stationLabel: UILabel = UILabel()
    private let endStationLabel: UILabel = UILabel()
    private let busNumberLabel = PaddingLabel(top: 4, left: 8, bottom: 4, right: 8)
    private let directionLabel: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Course Detail Step UI
    private func setupUI() {
        addSubViews(
            trafficImageView,
            stationLabel,
            directionLabel,
            busNumberLabel,
            endStationLabel
        )
        
        trafficImageView.contentMode = .scaleAspectFit
    }
    
    private func setupAutoLayout() {
        trafficImageView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.size.equalTo(26)
        }
        
        stationLabel.snp.makeConstraints { make in
            make.leading.equalTo(trafficImageView.snp.trailing).offset(8)
            make.centerY.equalTo(trafficImageView)
            make.trailing.lessThanOrEqualToSuperview()
        }
    }
    
    
    // MARK: - CourseStepCell Configure
    func configure(leg: Legs, isLast: Bool) {
        guard leg.mode != .walk else {
            isHidden = true
            return
        }
        
        isHidden = false
        
        stationLabel.attributedText = AtchaFont.R_12(leg.start?.name ?? "", color: AtchaColor.white)
        
        busNumberLabel.isHidden = true
        directionLabel.isHidden = true
        endStationLabel.isHidden = true
        
        busNumberLabel.snp.removeConstraints()
        directionLabel.snp.removeConstraints()
        endStationLabel.snp.removeConstraints()
        
        
        switch leg.mode {
        case .bus:
            let key = leg.type ?? "0"
            let imageName = busIcon[key] ?? busDefaultIcon
            trafficImageView.image = UIImage(named: imageName)
            
            busNumberLabel.isHidden = false
            busNumberLabel.attributedText = AtchaFont.R_12("\(leg.busName)", color: AtchaColor.white)
            
            let color = TransportMode.busColor[key] ?? AtchaColor.gray300
            busNumberLabel.backgroundColor = color
            
            busNumberLabel.layer.cornerRadius = 6
            busNumberLabel.clipsToBounds = true
            
            busNumberLabel.snp.remakeConstraints { make in
                make.leading.equalTo(stationLabel.snp.leading)
                make.top.equalTo(stationLabel.snp.bottom).offset(8)
            }
            
            if isLast {
                endStationLabel.isHidden = false
                endStationLabel.attributedText = AtchaFont.R_12(leg.end?.name ?? "", color: AtchaColor.white)
                
                endStationLabel.snp.makeConstraints { make in
                    make.leading.equalTo(stationLabel.snp.leading)
                    make.top.equalTo(busNumberLabel.snp.bottom).offset(8)
                    make.bottom.equalToSuperview()
                }
            } else {
                busNumberLabel.snp.remakeConstraints { make in
                    make.leading.equalTo(stationLabel.snp.leading)
                    make.top.equalTo(stationLabel.snp.bottom).offset(8)
                    make.bottom.equalToSuperview()
                }
            }
        case .subway:
            let key = leg.type ?? "0"
            let imageName = subwayIcon[key] ?? subwayDefaultIcon
            trafficImageView.image = UIImage(named: imageName)
            
            directionLabel.isHidden = false
            directionLabel.attributedText = AtchaFont.R_12("\(leg.subwayFinalStation ?? "")행", color: AtchaColor.gray300)
            
            directionLabel.snp.remakeConstraints { make in
                make.leading.equalTo(stationLabel.snp.leading)
                make.top.equalTo(stationLabel.snp.bottom).offset(8)
            }
            
            if isLast {
                endStationLabel.isHidden = false
                endStationLabel.attributedText = AtchaFont.R_12(leg.end?.name ?? "", color: AtchaColor.white)
                
                endStationLabel.snp.remakeConstraints { make in
                    make.leading.equalTo(stationLabel.snp.leading)
                    make.top.equalTo(directionLabel.snp.bottom).offset(8)
                    make.bottom.equalToSuperview()
                }
            } else {
                directionLabel.snp.remakeConstraints { make in
                    make.leading.equalTo(stationLabel.snp.leading)
                    make.top.equalTo(stationLabel.snp.bottom).offset(8)
                    make.bottom.equalToSuperview()
                }
            }
        default:
            trafficImageView.image = nil
            stationLabel.snp.remakeConstraints { make in
                make.leading.equalTo(trafficImageView.snp.trailing).offset(8)
                make.top.equalTo(trafficImageView.snp.top)
                make.trailing.lessThanOrEqualToSuperview()
                make.bottom.equalToSuperview()
            }
        }
    }
}
