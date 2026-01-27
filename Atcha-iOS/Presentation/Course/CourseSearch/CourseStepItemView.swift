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
    private let lineView: UIView = UIView()
    private let endPointView: UIView = UIView()
    
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
            lineView,
            trafficImageView,
            stationLabel,
            busNumberLabel,
            endStationLabel,
            endPointView
        )
        
        trafficImageView.contentMode = .scaleAspectFit
        lineView.backgroundColor = AtchaColor.gray910
    }
    
    private func setupAutoLayout() {
        trafficImageView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.size.equalTo(26)
        }
        
        lineView.snp.makeConstraints { make in
            make.top.equalTo(trafficImageView.snp.top).offset(5)
            make.centerX.equalTo(trafficImageView)
            make.width.equalTo(2)
            make.bottom.equalToSuperview().offset(10 )
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
        endStationLabel.isHidden = true
        endPointView.isHidden = true
        
        busNumberLabel.snp.removeConstraints()
        endStationLabel.snp.removeConstraints()
        endPointView.snp.removeConstraints()
        
        
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
                    make.bottom.equalToSuperview().inset(8)
                }
                
                endPointView.isHidden = false
                endPointView.layer.cornerRadius = 5
                endPointView.backgroundColor = AtchaColor.gray910
                
                endPointView.snp.makeConstraints { make in
                    make.centerX.equalTo(lineView)
                    make.bottom.equalTo(lineView.snp.bottom)
                    make.size.equalTo(10)
                }
                
                lineView.snp.remakeConstraints { make in
                    make.top.equalTo(trafficImageView.snp.top).offset(5)
                    make.centerX.equalTo(trafficImageView)
                    make.width.equalTo(2)
                    make.bottom.equalToSuperview().inset(10)
                }
                
            } else {
                busNumberLabel.snp.remakeConstraints { make in
                    make.leading.equalTo(stationLabel.snp.leading)
                    make.top.equalTo(stationLabel.snp.bottom).offset(8)
                    make.bottom.equalToSuperview().inset(8)
                }
            }
        case .subway:
            let key = leg.type ?? "0"
            let imageName = subwayIcon[key] ?? subwayDefaultIcon
            trafficImageView.image = UIImage(named: imageName)
            
            if isLast {
                endStationLabel.isHidden = false
                endStationLabel.attributedText = AtchaFont.R_12(leg.end?.name ?? "", color: AtchaColor.white)
                
                endStationLabel.snp.remakeConstraints { make in
                    make.leading.equalTo(stationLabel.snp.leading)
                    make.top.equalTo(stationLabel.snp.bottom).offset(8)
                    make.bottom.equalToSuperview().inset(8)
                }
                
                endPointView.isHidden = false
                endPointView.layer.cornerRadius = 5
                endPointView.backgroundColor = AtchaColor.gray800
                
                endPointView.snp.makeConstraints { make in
                    make.centerX.equalTo(lineView)
                    make.bottom.equalTo(lineView.snp.bottom)
                    make.size.equalTo(10)
                }
                
                lineView.snp.remakeConstraints { make in
                    make.top.equalTo(trafficImageView.snp.top).offset(5)
                    make.centerX.equalTo(trafficImageView)
                    make.width.equalTo(2)
                    make.bottom.equalToSuperview().inset(10)
                }
                
            } else {
                stationLabel.snp.remakeConstraints { make in
                    make.leading.equalTo(trafficImageView.snp.trailing).offset(8)
                    make.centerY.equalTo(trafficImageView)
                    make.trailing.lessThanOrEqualToSuperview()
                    make.bottom.equalToSuperview().inset(8)
                }
            }
        default:
            trafficImageView.image = nil
            stationLabel.snp.remakeConstraints { make in
                make.leading.equalTo(trafficImageView.snp.trailing).offset(8)
                make.top.equalTo(trafficImageView.snp.top)
                make.trailing.lessThanOrEqualToSuperview()
                make.bottom.equalToSuperview().inset(8)
            }
        }
    }
}
