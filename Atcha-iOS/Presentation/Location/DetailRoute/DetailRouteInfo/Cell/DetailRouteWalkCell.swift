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
        contentView.addSubViews(lineImageView, summaryLabel)
        contentView.backgroundColor = .clear
        lineImageView.image = UIImage.dotLine
        summaryLabel.numberOfLines = 1
        summaryLabel.textAlignment = .left
    }
    
    private func setupAutoLayout() {
        lineImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(78)
            make.centerY.equalToSuperview()
            make.width.equalTo(4)
            make.height.equalToSuperview()
        }
        summaryLabel.snp.makeConstraints { make in
            make.leading.equalTo(lineImageView.snp.trailing).offset(24)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(info: LegTrafficInfo) {
        guard let sectionTime = info.sectionTime else { return }
        let timeText = AtchaFont.B6_R_14("\(sectionTime) 걷기", color: .gray200)
        let distanceText = AtchaFont.B6_R_14(" \(info.distance ?? 0)m", color: .gray500)
        let combined = NSMutableAttributedString()
        combined.append(timeText)
        combined.append(distanceText)
        
        summaryLabel.attributedText = combined
    }
}
