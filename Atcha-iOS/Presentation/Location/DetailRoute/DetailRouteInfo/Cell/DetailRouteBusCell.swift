//
//  DetailRouteBusCell.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/31/25.
//

import UIKit
import SnapKit

final class DetailRouteBusCell: UICollectionViewCell {
    static let id = "DetailRouteBusCell"
    
    // MARK: - Left Line UI
    private let iconImageView = UIImageView()
    private let stickView = UIView()
    private let circleView: UIView = UIView()
    
    // MARK: - Top (승차 정보)
    private let startLabel: UILabel = UILabel()
    
    // MARK: - Bus Info
    private let busBackView: UIView = UIView()
    private let busLabel: UILabel = UILabel()
    private let busDetailArrowImageView: UIImageView = UIImageView(image: UIImage.chevronRight)
    private let stationListStackView = UIStackView()
    
    // MARK: - Summary
    private let summaryLabel: UILabel = UILabel()
    
    // MARK: - 하차 정보
    private let endLabel: UILabel = UILabel()
    
    private var isExpanded: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        contentView.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubViews(iconImageView, stickView, circleView,
                                startLabel,
                                busBackView, summaryLabel, stationListStackView,
                                endLabel)
        
        iconImageView.contentMode = .scaleAspectFill
        circleView.setCornerRadius(8)
        
        busBackView.setCornerRadius(4)
        busBackView.addSubViews(busLabel, busDetailArrowImageView)
        
        stationListStackView.axis = .vertical
        stationListStackView.spacing = 10
        stationListStackView.isHidden = false
    }
    
    private func setupConstraints() {
        iconImageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview().offset(16)
        }
        
        stickView.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).inset(5)
            $0.centerX.equalTo(iconImageView)
            $0.bottom.equalTo(circleView.snp.top)
            $0.width.equalTo(4)
        }
        
        circleView.snp.makeConstraints {
            $0.leading.equalTo(iconImageView)
            $0.bottom.equalToSuperview().inset(8)
            $0.centerX.equalTo(iconImageView)
            $0.size.equalTo(16)
        }
        
        startLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(5)
            $0.leading.equalTo(iconImageView.snp.trailing).offset(18)
            $0.height.equalTo(20)
        }
        
        busBackView.snp.makeConstraints {
            $0.top.equalTo(startLabel.snp.bottom).offset(16)
            $0.leading.equalTo(startLabel)
            $0.height.equalTo(26)
        }
        
        busLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(8)
            $0.centerY.equalToSuperview()
        }
        
        busDetailArrowImageView.snp.makeConstraints {
            $0.leading.equalTo(busLabel.snp.trailing).offset(4)
            $0.trailing.equalToSuperview().inset(8)
            $0.centerY.equalTo(busLabel)
            $0.size.equalTo(12)
        }
        
        summaryLabel.snp.makeConstraints {
            $0.top.equalTo(busBackView.snp.bottom).offset(16)
            $0.leading.equalTo(busBackView)
        }
        
        stationListStackView.snp.makeConstraints {
            $0.top.equalTo(summaryLabel.snp.bottom).offset(16)
            $0.leading.equalTo(startLabel)
            $0.bottom.equalTo(endLabel.snp.top)
        }
        
        endLabel.snp.makeConstraints {
            $0.top.equalTo(summaryLabel.snp.bottom).offset(36)
            $0.leading.equalTo(summaryLabel)
        }
    }
    
    func configure(info: LegTrafficInfo) {
        guard let passStopList = info.passStopList,
              let firstStation = passStopList.first,
              let lastStation = passStopList.last,
              let sectionTime = info.sectionTime else { return }
        
        iconImageView.image = info.mode?.getIcon(for: info.type ?? "")
        stickView.backgroundColor = info.mode?.getColor(for: info.type ?? "")
        circleView.backgroundColor = info.mode?.getColor(for: info.type ?? "")
        
        let startCombinedLabel = NSMutableAttributedString()
        startCombinedLabel.append(AtchaFont.B3_M_15("\(firstStation.stationName ?? "")",
                                                    color: .gray100))
        startCombinedLabel.append(AtchaFont.B3_M_15(" 승차", color: .gray500))
        startLabel.attributedText = startCombinedLabel
        
        let endCombinedLabel = NSMutableAttributedString()
        endCombinedLabel.append(AtchaFont.B3_M_15("\(lastStation.stationName ?? "")",
                                                  color: .gray100))
        endCombinedLabel.append(AtchaFont.B3_M_15(" 하차", color: .gray500))
        endLabel.attributedText = endCombinedLabel
        
        busBackView.backgroundColor = info.mode?.getColor(for: info.type ?? "")
        busDetailArrowImageView.tintColor = .white
        busLabel.attributedText = AtchaFont.B6_R_14(info.busName ?? "", color: .white)
        
        summaryLabel.attributedText = AtchaFont.B7_M_13("\(sectionTime), \(passStopList.count)개 정류장 이동", color: .white)
        
//        stationListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        passStopList.forEach { list in
            let label = UILabel()
            label.attributedText = AtchaFont.B4_R_15(list.stationName ?? "", color: .gray200)
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            stationListStackView.addArrangedSubview(label)
        }
    }
}
