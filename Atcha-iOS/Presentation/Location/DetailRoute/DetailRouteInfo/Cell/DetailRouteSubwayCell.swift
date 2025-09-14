//
//  DetailRouteSubwayCell.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/31/25.
//

import UIKit
import SnapKit

final class DetailRouteSubwayCell: UICollectionViewCell {
    static let id = "DetailRouteSubwayCell"
    
    // MARK: - Left Line UI
    private let iconImageView = UIImageView()
    private let stickView = UIView()
    private let circleView: UIView = UIView()
    
    // MARK: - Top (승차 정보)
    private let startLabel: UILabel = UILabel()
    private let stationListStackView = UIStackView()
    
    // MARK: 도착 예정 시간
    private let timeStartLabel: UILabel = UILabel()
    private let timeEndLabel: UILabel = UILabel()
    
    // MARK: - Summary
    private let summaryLabel: UILabel = UILabel()
    private let summaryButton: UIButton = UIButton()
    
    // MARK: - 하차 정보
    private let endLabel: UILabel = UILabel()
    
    private var stationInfos: [PassStopList] = []
    private var isExpanded: Bool = false
    var didTapSummary: (() -> Void)?
    
    private var stationListStackViewTopConstraint: Constraint?
    private var stationListStackViewBottomConstraint: Constraint?
    private var endLabelTopConstraintWithoutStack: Constraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupAction()
        contentView.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubViews(iconImageView, stickView, circleView,
                                startLabel, timeStartLabel, timeEndLabel,
                                summaryLabel, summaryButton, stationListStackView,
                                endLabel)
        
        iconImageView.contentMode = .scaleAspectFill
        circleView.setCornerRadius(8)
        
        summaryButton.setImage(UIImage.chevronDown, for: .normal)
        summaryButton.imageView?.tintColor = .gray200
        
        stationListStackView.axis = .vertical
        stationListStackView.spacing = 10
        stationListStackView.isHidden = true
        
        timeStartLabel.attributedText = AtchaFont.M_11("22:32", color: .gray200)
        timeStartLabel.textAlignment = .center
        timeStartLabel.setCornerRadius(4)
        timeStartLabel.backgroundColor = .gray920
        
        timeEndLabel.attributedText = AtchaFont.M_11("22:32", color: .gray200)
        timeEndLabel.textAlignment = .center
        timeEndLabel.setCornerRadius(4)
        timeEndLabel.backgroundColor = .gray920
    }
    
    private func setupConstraints() {
        timeStartLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalToSuperview()
            $0.width.equalTo(38)
            $0.height.equalTo(18)
        }
        
        timeEndLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
            $0.width.equalTo(38)
            $0.height.equalTo(18)
        }
        
        iconImageView.snp.makeConstraints {
            $0.leading.equalTo(timeStartLabel.snp.trailing).offset(10)
            $0.centerY.equalTo(timeStartLabel.snp.centerY)
            $0.size.equalTo(36)
        }
        
        startLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(10)
            $0.centerY.equalTo(timeStartLabel.snp.centerY)
            $0.height.equalTo(20)
        }
        
        summaryLabel.snp.makeConstraints {
            $0.top.equalTo(startLabel.snp.bottom).offset(40)
            $0.leading.equalTo(startLabel)
        }
        
        summaryButton.snp.makeConstraints { make in
            make.centerY.equalTo(summaryLabel.snp.centerY)
            make.leading.equalTo(summaryLabel.snp.trailing).offset(4)
            make.size.equalTo(10)
        }
        
        stickView.snp.makeConstraints {
            $0.centerX.equalTo(iconImageView.snp.centerX)
            $0.top.equalTo(iconImageView.snp.bottom).inset(5)
            $0.bottom.equalTo(circleView.snp.top).inset(5)
            $0.width.equalTo(4)
        }
        
        stationListStackView.snp.makeConstraints {
            $0.leading.equalTo(startLabel)
            stationListStackViewTopConstraint = $0.top.equalTo(summaryLabel.snp.bottom).offset(16).constraint
            stationListStackViewBottomConstraint = $0.bottom.equalTo(endLabel.snp.top).offset(-12).constraint
        }
        
        circleView.snp.makeConstraints {
            $0.size.equalTo(16)
            $0.centerX.equalTo(iconImageView.snp.centerX)
            $0.bottom.equalTo(endLabel.snp.bottom)
        }
        
        endLabel.snp.makeConstraints {
            endLabelTopConstraintWithoutStack = $0.top.equalTo(summaryLabel.snp.bottom).offset(36).constraint
            $0.leading.trailing.equalTo(stationListStackView)
            $0.bottom.equalToSuperview()
        }
    }
    
    private func setupAction() {
        summaryButton.addTarget(self,
                                action: #selector(handleSummaryButton),
                                for: .touchUpInside)
        
        summaryLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSummaryButton))
        summaryLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleSummaryButton() {
        isExpanded.toggle()
        stationListStackView.isHidden = !isExpanded
        
        stationListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        addStationNameLabel(info: stationInfos)
        
        stationListStackViewTopConstraint?.isActive = isExpanded
        stationListStackViewBottomConstraint?.isActive = isExpanded
        endLabelTopConstraintWithoutStack?.isActive = !isExpanded
        
        UIView.animate(withDuration: 0.3) { self.layoutIfNeeded() }
        didTapSummary?()
    }
    
    func configure(info: LegTrafficInfo?) {
        stationInfos = []
        guard let info = info,
              let passStopList = info.passStopList,
              let firstStation = passStopList.first,
              let lastStation = passStopList.last,
              let sectionTime = info.sectionTime else { return }
        
        stationInfos = passStopList
        iconImageView.image = info.mode?.getIcon(for: info.type ?? "")
        stickView.backgroundColor = info.mode?.getColor(for: info.type ?? "")
        circleView.backgroundColor = info.mode?.getColor(for: info.type ?? "")
        
        let startCombinedLabel = NSMutableAttributedString()
        startCombinedLabel.append(AtchaFont.B3_M_15("\(firstStation.stationName ?? "")역",
                                                    color: .gray100))
        startCombinedLabel.append(AtchaFont.B3_M_15(" 승차", color: .gray500))
        startLabel.attributedText = startCombinedLabel
        
        let endCombinedLabel = NSMutableAttributedString()
        endCombinedLabel.append(AtchaFont.B3_M_15("\(lastStation.stationName ?? "")역",
                                                  color: .gray100))
        endCombinedLabel.append(AtchaFont.B3_M_15(" 하차", color: .gray500))
        endLabel.attributedText = endCombinedLabel
        
        summaryLabel.attributedText = AtchaFont.B7_M_13("\(sectionTime), \(passStopList.count)개 정류장 이동", color: .white)
        addStationNameLabel(info: stationInfos)
    }
    
    private func addStationNameLabel(info: [PassStopList]) {
        info.dropLast().forEach { list in
            let label = UILabel()
            label.attributedText = AtchaFont.B4_R_15(list.stationName ?? "", color: .gray200)
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            stationListStackView.addArrangedSubview(label)
        }
    }
}
