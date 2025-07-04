//
//  CourseCell.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/4/25.
//

import UIKit
import SnapKit

class CourseCell: UICollectionViewCell {
    static let reusableId: String = "CourseCell"
    
    private let containerView: UIView = UIView()
    private let totalTimeLabel: UILabel = UILabel()
    
    private let detailStack: UIStackView = UIStackView()
    private let detailLabel: UILabel = UILabel()
    private let detailImageView: UIImageView = UIImageView()
    
    private let timeStack: UIStackView = UIStackView()
    private let departTimeContainer: UIView = UIView()
    private let departTimeLabel: UILabel = UILabel()
    private let departLabel: UILabel = UILabel()
    private let boardingTimeContainer: UIView = UIView()
    private let boardingTimeLabel: UILabel = UILabel()
    private let boardingLabel: UILabel = UILabel()
    
    private let courseContainer: UIView = UIView()
    private let courseDownButton: UIImageView = UIImageView()
    private let courseStack: UIStackView = UIStackView()
    private let courseCompactStack: UIStackView = UIStackView()
    private let courseDetailStack: UIStackView = UIStackView()
    private var isExpanded: Bool = false
    private let alarmRegisterButton: AtchaButton = AtchaButton(text: "막차 알림 받기", size: .h44, style: .filled(.defaultGray), image: UIImage.bellOutlined) {
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Course UI
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        containerView.backgroundColor = AtchaColor.gray940
        containerView.layer.cornerRadius = 12
        
        detailStack.addArrangedSubview(detailLabel)
        detailStack.addArrangedSubview(detailImageView)
        detailStack.axis = .horizontal
        detailStack.spacing = 2
        
        detailLabel.attributedText = AtchaFont.R_12("상세보기", color: AtchaColor.gray200)
        detailImageView.image = .chevronRight
        detailImageView.tintColor = AtchaColor.gray200
        
        departTimeContainer.backgroundColor = AtchaColor.gray920
        departTimeContainer.layer.cornerRadius = 12
        departTimeContainer.addSubview(departTimeLabel)
        departLabel.attributedText = AtchaFont.B7_M_13("출발", color: AtchaColor.gray200)
        
        boardingTimeContainer.backgroundColor = AtchaColor.gray920
        boardingTimeContainer.layer.cornerRadius = 12
        boardingTimeContainer.addSubview(boardingTimeLabel)
        boardingLabel.attributedText = AtchaFont.B7_M_13("탑승", color: AtchaColor.gray200)
        
        timeStack.addArrangedSubview(departTimeContainer)
        timeStack.addArrangedSubview(departLabel)
        timeStack.addArrangedSubview(boardingTimeContainer)
        timeStack.addArrangedSubview(boardingLabel)
        timeStack.axis = .horizontal
        timeStack.spacing = 5
        
        courseContainer.backgroundColor = AtchaColor.opacity200
        courseContainer.layer.cornerRadius = 8
        courseStack.axis = .horizontal
        courseStack.spacing = 4
        
        courseCompactStack.axis = .horizontal
        courseCompactStack.spacing = 4
        courseCompactStack.alignment = .center
        courseCompactStack.distribution = .equalCentering
        courseCompactStack.isHidden = false
        
        courseDetailStack.axis = .vertical
        courseDetailStack.spacing = 8
        courseDetailStack.isHidden = true
        
        courseStack.addArrangedSubview(courseCompactStack)
        
        courseDownButton.image = UIImage.chevronDown
        courseDownButton.tintColor = AtchaColor.gray400
        courseDownButton.contentMode = .scaleAspectFit
        courseDownButton.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCourseDetail))
        courseDownButton.addGestureRecognizer(tapGesture)
        courseContainer.addSubViews(courseStack, courseDownButton)
        
        containerView.addSubViews(totalTimeLabel, detailStack, timeStack, courseContainer, alarmRegisterButton)
        contentView.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.top).offset(14)
            make.bottom.equalTo(contentView.snp.bottom).inset(14)
            make.leading.equalTo(contentView.snp.leading).offset(16)
            make.trailing.equalTo(contentView.snp.trailing).inset(16)
        }
        
        totalTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.top).offset(16)
            make.leading.equalTo(containerView.snp.leading).offset(16)
        }
        
        detailStack.snp.makeConstraints { make in
            make.top.equalTo(containerView.snp.top).offset(23)
            make.trailing.equalTo(containerView.snp.trailing).inset(16)
        }
        
        detailImageView.snp.makeConstraints { make in
            make.size.equalTo(12)
        }
        
        timeStack.snp.makeConstraints { make in
            make.top.equalTo(totalTimeLabel.snp.bottom).offset(20)
            make.leading.equalTo(containerView.snp.leading).offset(16)
        }
        
        departTimeContainer.snp.makeConstraints { make in
            make.width.equalTo(52)
            make.height.equalTo(24)
        }
        
        departTimeLabel.snp.makeConstraints { make in
            make.center.equalTo(departTimeContainer)
        }
        
        boardingTimeContainer.snp.makeConstraints { make in
            make.width.equalTo(52)
            make.height.equalTo(24)
        }
        
        boardingTimeLabel.snp.makeConstraints { make in
            make.center.equalTo(boardingTimeContainer)
        }
        
        courseContainer.snp.makeConstraints { make in
            make.top.equalTo(timeStack.snp.bottom).offset(20)
            make.leading.equalTo(containerView.snp.leading).offset(16)
            make.trailing.equalTo(containerView.snp.trailing).inset(16)
        }
        
        courseStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(7)
            make.top.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(4)
        }
        
        courseDownButton.snp.makeConstraints { make in
            make.size.equalTo(16)
            make.trailing.equalToSuperview().inset(10)
            make.top.equalToSuperview().inset(10)
        }
        
        alarmRegisterButton.snp.makeConstraints { make in
            make.top.equalTo(courseContainer.snp.bottom).offset(22)
            make.leading.equalTo(containerView.snp.leading).offset(16)
            make.trailing.equalTo(containerView.snp.trailing).inset(16)
            make.bottom.equalTo(containerView.snp.bottom).inset(16)
        }
    }
    
    // MARK: - CourseCell Configure
    func configure(with course: Course) {
        if let totalTime = course.totalTime {
            totalTimeLabel.attributedText = AtchaFont.H2_B_22("\(totalTime.toHourMinuteString)", color: AtchaColor.white)
        }
        
        if let departTime = course.departureDateTime {
            departTimeLabel.attributedText = AtchaFont.B7_M_13(departTime.toTimeString, color: AtchaColor.main)
        }
        
        if let boardingLeg = course.legs.first(where: { $0.mode == "SUBWAY" || $0.mode == "BUS" }),
           let boardingTime = boardingLeg.departureDateTime {
            boardingTimeLabel.attributedText = AtchaFont.B7_M_13(boardingTime.toTimeString, color: AtchaColor.white)
        } else {
            boardingTimeLabel.attributedText = AtchaFont.B7_M_13("-", color: AtchaColor.white)
        }
        
        courseCompactStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, leg) in course.legs.enumerated() {
            switch leg.mode {
            case "WALK":
                let walkIcon = UIImageView(image: UIImage.routeCircleWalkGray700)
                walkIcon.snp.makeConstraints { $0.size.equalTo(26) }
                courseCompactStack.addArrangedSubview(walkIcon)
                
            case "BUS":
                if let type = leg.type,
                   let imageName = busIcon[type],
                   let image = UIImage(named: imageName) {
                    let busIconView = UIImageView(image: image)
                    busIconView.snp.makeConstraints { $0.size.equalTo(26) }
                    courseCompactStack.addArrangedSubview(busIconView)
                }
                
            case "SUBWAY":
                if let type = leg.type,
                   let imageName = subwayIcon[type],
                   let image = UIImage(named: imageName) {
                    let subwayIconView = UIImageView(image: image)
                    subwayIconView.snp.makeConstraints { $0.size.equalTo(26) }
                    courseCompactStack.addArrangedSubview(subwayIconView)
                }
                
            default:
                break
            }
            
            if index < course.legs.count - 1 {
                let arrow = UIImageView(image: UIImage.chevronRight)
                arrow.tintColor = AtchaColor.gray400
                arrow.contentMode = .scaleAspectFit
                arrow.snp.makeConstraints { $0.size.equalTo(12) }
                courseCompactStack.addArrangedSubview(arrow)
            }
        }
        
        courseDetailStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, leg) in course.legs.enumerated() {
            let stepView = CourseStepView()
            
            var title: String = ""
            var icon: UIImage?
            
            switch leg.mode {
            case "WALK":
                let isFirstWalk = index == 0
                let isLastWalk = index == course.legs.count - 1
                let showTopLine = !isFirstWalk
                let showBottomLine = !isLastWalk
                
                title = "걷기"
                icon = UIImage.routeCircleWalkGray700
                stepView.configure(
                    icon: icon,
                    title: title,
                    time: leg.sectionTime,
                    showTopLine: showTopLine,
                    showBottomLine: showBottomLine,
                    isWalk: true,
                    isGetOff: false
                )
                
                courseDetailStack.addArrangedSubview(stepView)
                
            case "BUS", "SUBWAY":
                let isFirstWalk = index == 0
                let isLastWalk = index == course.legs.count - 1
                let showTopLine = !isFirstWalk
                let showBottomLine = !isLastWalk
                
                if let startName = leg.start.name, let endName = leg.end.name {
                    let startStepView = CourseStepView()
                    startStepView.configure(
                        icon: UIImage(named: leg.mode == "BUS"
                                      ? busIcon[leg.type ?? 0] ?? ""
                                      : subwayIcon[leg.type ?? 0] ?? ""),
                        title: "\(startName) 승차",
                        time: 12,
                        showTopLine: showTopLine,
                        showBottomLine: showBottomLine,
                        isWalk: false,
                        isGetOff: false
                    )
                    courseDetailStack.addArrangedSubview(startStepView)
                    
                    let endStepView = CourseStepView()
                    endStepView.configure(
                        icon: UIImage(named: leg.mode == "BUS"
                                      ? busGetOffIcon[leg.type ?? 0] ?? ""
                                      : subwayIcon[leg.type ?? 0] ?? ""),
                        title: "\(endName) 하차",
                        time: nil,
                        showTopLine: false,
                        showBottomLine: showBottomLine,
                        isWalk: true,
                        isGetOff: true
                    )
                    courseDetailStack.addArrangedSubview(endStepView)
                }
            default:
                title = "알 수 없음"
                icon = UIImage.routeCircleWalkGray700
            }
        }
    }
    
    // MARK: - Course Detail Toggle Handler
    @objc private func toggleCourseDetail() {
        isExpanded.toggle()
        courseDownButton.image = isExpanded ? UIImage.chevronUp : UIImage.chevronDown
        
        if isExpanded {
            courseStack.removeArrangedSubview(courseCompactStack)
            courseStack.addArrangedSubview(courseDetailStack)
            courseCompactStack.isHidden = true
            courseDetailStack.isHidden = false
            
        } else {
            courseStack.removeArrangedSubview(courseDetailStack)
            courseStack.addArrangedSubview(courseCompactStack)
            courseCompactStack.isHidden = false
            courseDetailStack.isHidden = true
            
        }
        
        setNeedsLayout()
        layoutIfNeeded()
        
        if let collectionView = self.superview as? UICollectionView {
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
}

extension CourseCell{
    // MARK: - Course Layout
    static func courseLayout() -> NSCollectionLayoutSection {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(300))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        return section
    }
}
