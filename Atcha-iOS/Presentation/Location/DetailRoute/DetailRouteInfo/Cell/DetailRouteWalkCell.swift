//
//  DetailRouteWalkCell.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/31/25.
//

import UIKit
import SnapKit

final class DetailRouteWalkCell: UICollectionViewCell {
    static let id: String = "DetailRouteWalkCell"
    
    private let animationView: DetailRouteAnimationView = DetailRouteAnimationView()
    private let animationIconImageView: UIImageView = UIImageView()
    
    private let lineImageView: UIImageView = UIImageView()
    private let timeLabel: UILabel = UILabel()
    private let distanceLabel: UILabel = UILabel()
    private let summaryLabel: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        animationView.isHidden = true
        animationView.stopAnimation()
        backgroundColor = .clear
    }
    
    private func setupUI() {
        contentView.addSubViews(lineImageView, summaryLabel, animationView, animationIconImageView)
        contentView.backgroundColor = .clear
        lineImageView.image = UIImage.dotLine
        animationIconImageView.image = UIImage.walkGray600
        animationIconImageView.isHidden = true
        animationView.isHidden = true
        summaryLabel.numberOfLines = 1
        summaryLabel.textAlignment = .left
    }
    
    private func setupAutoLayout() {
        animationView.snp.makeConstraints { make in
            make.centerX.equalTo(lineImageView.snp.centerX)
            make.centerY.equalToSuperview()
        }
        
        animationIconImageView.snp.makeConstraints { make in
            make.centerX.equalTo(lineImageView.snp.centerX)
            make.centerY.equalToSuperview()
        }
        
        lineImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(75)
            make.verticalEdges.equalToSuperview()
            make.width.equalTo(4)
        }
        
        summaryLabel.snp.makeConstraints { make in
            make.leading.equalTo(lineImageView.snp.trailing).offset(24)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(info: LegTrafficInfo?) {
        guard let sectionTime = info?.sectionTime else { return }
        let timeText = AtchaFont.B6_R_14("\(sectionTime) 걷기", color: .gray200)
        let distanceText = AtchaFont.B6_R_14(" \(info?.distance ?? 0)m", color: .gray500)
        let combined = NSMutableAttributedString()
        combined.append(timeText)
        combined.append(distanceText)
        
        summaryLabel.attributedText = combined
        
        print("info : \(info)")
        
        if isCurrentTimeBetween(startTime: info?.startTime, endTime: info?.endTime) {
            isNowUserLocationArrived()
        }
    }
    
    private func isCurrentTimeBetween(startTime: String?, endTime: String?) -> Bool {
        guard let startTime, let endTime else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        
        // ⛳️ 현재 시각을 '오늘 날짜 기준 시:분' 으로 고정
        let todayNow = calendar.date(bySettingHour: calendar.component(.hour, from: now),
                                     minute: calendar.component(.minute, from: now),
                                     second: 0,
                                     of: now)!
        
        // ⏰ startTime, endTime → 시/분 정수 변환
        let startComponents = startTime.split(separator: ":").compactMap { Int($0) }
        let endComponents = endTime.split(separator: ":").compactMap { Int($0) }
        
        guard startComponents.count == 2, endComponents.count == 2 else { return false }
        
        // ⏳ 오늘 날짜 기준으로 Date 생성
        guard let todayStart = calendar.date(bySettingHour: startComponents[0],
                                             minute: startComponents[1],
                                             second: 0,
                                             of: now),
              let todayEnd = calendar.date(bySettingHour: endComponents[0],
                                           minute: endComponents[1],
                                           second: 0,
                                           of: now)
        else {
            return false
        }
        // 🌙 자정 넘김 처리
        if todayEnd < todayStart {
            return todayNow >= todayStart || todayNow < todayEnd
        } else {
            return todayNow >= todayStart && todayNow < todayEnd
        }
    }
    
    func isNowUserLocationArrived() {
        animationIconImageView.isHidden = false
        animationView.isHidden = false
        animationView.startAnimationIfNeeded(forceRestart: true)
        backgroundColor = UIColor.opacity100
    }
}
