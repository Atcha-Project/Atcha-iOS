//
//  CourseCell.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/4/25.
//

import UIKit
import SnapKit

final class CourseCell: UICollectionViewCell {
    static let reusableId: String = "CourseCell"
    var onDetailTapped: (() -> Void)?
    var onGetAlarmTapped: (() -> Void)?
    
    private let containerView: UIView = UIView()
    private let flagLabel: UILabel = UILabel()
    private let timeLabel: UILabel = UILabel()
    private let departureTimeLabel: PaddingLabel = PaddingLabel(top: 4, left: 6, bottom: 4, right: 6)
    private let departureLabel: UILabel = UILabel()
    private let progressView: DetailRouteProgressView = DetailRouteProgressView()
    private let courseStepsStackView: CourseStepsStackView = CourseStepsStackView()
    
    private let alarmRegisterButton: AtchaButton = AtchaButton(text: "막차 알람 받기", size: .h44, style: .filled(.defaultGray), image: UIImage.bellFilled)
    
    
    private let detailTapGesture = UITapGestureRecognizer()
    private let registerTapGesture = UITapGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Course UI
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        containerView.backgroundColor = AtchaColor.gray950
        
        contentView.addSubview(containerView)
        containerView.addSubViews(
            flagLabel,
            timeLabel,
            departureTimeLabel,
            departureLabel,
            progressView,
            courseStepsStackView,
            alarmRegisterButton)
        
        detailTapGesture.addTarget(self, action: #selector(detailTapped))
        containerView.isUserInteractionEnabled = true
        containerView.addGestureRecognizer(detailTapGesture)
        
        registerTapGesture.addTarget(self, action: #selector(getAlarmTapped))
        alarmRegisterButton.isUserInteractionEnabled = true
        alarmRegisterButton.addGestureRecognizer(registerTapGesture)
    }
    
    private func setupAutoLayout() {
        containerView.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top)
            make.bottom.equalTo(contentView.snp.bottom)
            make.leading.equalTo(contentView.snp.leading)
            make.trailing.equalTo(contentView.snp.trailing)
        }
        
        flagLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.top.equalTo(flagLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
        }
        
        departureTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(timeLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(16)
        }
        
        departureLabel.snp.makeConstraints { make in
            make.centerY.equalTo(departureTimeLabel)
            make.leading.equalTo(departureTimeLabel.snp.trailing).offset(4)
        }
        
        progressView.snp.makeConstraints { make in
            make.top.equalTo(departureTimeLabel.snp.bottom).offset(18)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(16)
        }
        
        courseStepsStackView.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        alarmRegisterButton.snp.makeConstraints { make in
            make.height.equalTo(44).priority(.high)
            make.top.equalTo(courseStepsStackView.snp.bottom).offset(18)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }
    
    // MARK: - CourseCell Configure
    func configure(with model: CourseUIModel, isLast: Bool) {
        flagConfigure(isLast: isLast)
        let course = model.course
        
        if let totalTime = course.totalTime?.toHourMinuteString {
            timeLabel.attributedText = AtchaFont.H2_B_22(lineHeight: 28, "\(totalTime)", color: AtchaColor.white)
        }
        
        if let departureTime = course.departureDateTime {
            departureTimeLabel.attributedText = AtchaFont.B7_M_13(lineHeight: 15, "\(departureTime.convertedToHourMinute)", color: AtchaColor.white)
            departureTimeLabel.layer.cornerRadius = 8
            departureTimeLabel.clipsToBounds = true
            departureTimeLabel.backgroundColor = AtchaColor.gray930
            departureTimeLabel.layer.borderWidth = 1
            departureTimeLabel.layer.borderColor = AtchaColor.gray500.cgColor
        }
        
        departureLabel.attributedText = AtchaFont.B7_M_13("에 자리에서 출발", color: AtchaColor.gray200)
        
        progressView.configure(infos: course.toLegTrafficInfos())
        courseStepsStackView.configure(legs: course.legs)
    }
    
    private func flagConfigure(isLast: Bool) {
        if isLast {
            flagLabel.isHidden = false
            flagLabel.attributedText = AtchaFont.R_12("가장 늦은 막차", color: AtchaColor.main)
            
            flagLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(20)
                make.leading.equalToSuperview().offset(16)
            }
            
            timeLabel.snp.remakeConstraints { make in
                make.top.equalTo(flagLabel.snp.bottom).offset(4)
                make.leading.equalToSuperview().offset(16)
            }
        } else {
            flagLabel.isHidden = true
            flagLabel.snp.removeConstraints()
            
            timeLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(20)
                make.leading.equalToSuperview().offset(16)
            }
        }
    }
    
    @objc private func detailTapped() {
        onDetailTapped?()
    }
    
    @objc private func getAlarmTapped() {
        onGetAlarmTapped?()
    }
}

extension CourseCell{
    // MARK: - Course Layout
    static func courseLayout() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(600))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 6
        section.contentInsets = .init(top: 1, leading: 0, bottom: 0, trailing: 0)
        
        return section
    }
}

