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
    private let flagView: UIView = UIView()
    private let timeView: UIView = UIView()
    private let progressView: DetailRouteProgressView = DetailRouteProgressView()
    private let courseStepsStackView: CourseStepsStackView = CourseStepsStackView()
    
    private let alarmRegisterButton: AtchaButton = AtchaButton(text: "막차 알람 받기", size: .h44, style: .filled(.defaultGray), image: UIImage.bellOutlined)
    
    
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
        
        containerView.backgroundColor = AtchaColor.gray940
        containerView.layer.cornerRadius = 12
        
        contentView.addSubview(containerView)
        containerView.addSubViews(
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
            make.top.equalTo(contentView.snp.top).offset(14)
            make.bottom.equalTo(contentView.snp.bottom).inset(14)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.trailing.equalTo(contentView.snp.trailing).inset(16)
        }
        
        progressView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(16)
        }
        
        courseStepsStackView.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(22)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        alarmRegisterButton.snp.makeConstraints { make in
            make.height.equalTo(44).priority(.high)
            make.top.equalTo(courseStepsStackView.snp.bottom).offset(22)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }
    
    // MARK: - CourseCell Configure
    func configure(with model: CourseUIModel, isLast: Bool) {
        let course = model.course
        
        progressView.configure(infos: course.toLegTrafficInfos())
        courseStepsStackView.configure(legs: course.legs)
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
        section.interGroupSpacing = -10
        
        return section
    }
}

