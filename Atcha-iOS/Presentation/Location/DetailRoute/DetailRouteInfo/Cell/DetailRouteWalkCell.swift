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
        
        if isCurrentTimeBetween(startTime: info?.startTime, endTime: info?.endTime) {
            isNowUserLocationArrived()
        }
    }
    
    private func isCurrentTimeBetween(startTime: String?, endTime: String?) -> Bool {
        guard let startTime, let endTime else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        
        guard
            let start = formatter.date(from: startTime),
            let end = formatter.date(from: endTime)
        else {
            return false
        }
        
        // 현재 시각 (시:분 만 비교)
        let now = Date()
        let nowString = formatter.string(from: now)
        guard let nowTime = formatter.date(from: nowString) else {
            return false
        }
        
        return nowTime >= start && nowTime < end
    }
    
    func isNowUserLocationArrived() {
        animationIconImageView.isHidden = false
        animationView.isHidden = false
        animationView.startAnimationIfNeeded(forceRestart: true)
        backgroundColor = UIColor.opacity100
    }
}
