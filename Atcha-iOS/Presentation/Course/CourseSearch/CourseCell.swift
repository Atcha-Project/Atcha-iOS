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
    var onToggleExpanded: (() -> Void)?
    var onDetailTapped: (() -> Void)?

    private let courseTapGesture = UITapGestureRecognizer()
    private let detailTapGesture = UITapGestureRecognizer()
    
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
        setupGesture()
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
            make.height.equalTo(44).priority(.high)
            make.top.equalTo(courseContainer.snp.bottom).offset(22)
            make.leading.equalTo(containerView.snp.leading).offset(16)
            make.trailing.equalTo(containerView.snp.trailing).inset(16)
            make.bottom.equalTo(containerView.snp.bottom).inset(16)
        }
    }
    
    // MARK: - CourseCell Configure
    func configure(with model: CourseUIModel) {
        let course = model.course
        isExpanded = model.isExpanded
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
        
        if let totalTime = course.totalTime {
            totalTimeLabel.attributedText = AtchaFont.H2_B_22("\(totalTime.toHourMinuteStringFromSeconds)", color: AtchaColor.white)
        }
        
        if let departTime = course.departureDateTime {
            departTimeLabel.attributedText = AtchaFont.B7_M_13(departTime.convertedToHourMinute, color: AtchaColor.main)
        }
        
        if let boardingLeg = course.legs.first(where: { $0.mode?.rawValue == "SUBWAY" || $0.mode?.rawValue == "BUS" }),
           let boardingTime = boardingLeg.departureDateTime {
            boardingTimeLabel.attributedText = AtchaFont.B7_M_13(boardingTime.convertedToHourMinute, color: AtchaColor.white)
        } else {
            boardingTimeLabel.attributedText = AtchaFont.B7_M_13("-", color: AtchaColor.white)
        }
        
        courseCompactStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, leg) in course.legs.enumerated() {
            switch leg.mode {
            case .walk:
                let walkIcon = UIImageView(image: UIImage.walkGray700)
                walkIcon.snp.makeConstraints { $0.size.equalTo(26) }
                courseCompactStack.addArrangedSubview(walkIcon)
            case .bus:
                if let type = leg.type {
                    let imageName = busIcon[type] ?? busDefaultIcon
                    if let image = UIImage(named: imageName) {
                        let busIconView = UIImageView(image: image)
                        busIconView.snp.makeConstraints { $0.size.equalTo(26) }
                        courseCompactStack.addArrangedSubview(busIconView)
                    }
                }
            case .subway:
                if let type = leg.type {
                    let imageName = subwayIcon[type] ?? subwayDefaultIcon
                    if let image = UIImage(named: imageName) {
                        let subwayIconView = UIImageView(image: image)
                        subwayIconView.snp.makeConstraints { $0.size.equalTo(26) }
                        courseCompactStack.addArrangedSubview(subwayIconView)
                    }
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
            let prevLeg = index > 0 ? course.legs[index - 1] : nil
            let nextLeg = index < course.legs.count - 1 ? course.legs[index + 1] : nil
            
            var topLine: LineStyle = .none
            var bottomLine: LineStyle = .none
            
            // --------------------------
            // topLine 결정
            if index == 0 {
                topLine = .none
            } else {
                if prevLeg?.mode == .walk || leg.mode == .walk {
                    topLine = .dotted
                } else {
                    topLine = .solid
                }
            }
            
            // bottomLine 결정
            if index == course.legs.count - 1 {
                bottomLine = .none
            } else {
                if nextLeg?.mode == .walk || leg.mode == .walk {
                    bottomLine = .dotted
                } else {
                    bottomLine = .solid
                }
            }
            // --------------------------
            
            switch leg.mode {
            case .walk:
                let stepView = CourseStepView()
                stepView.configure(
                    icon: UIImage.walkGray700,
                    title: "걷기",
                    time: leg.sectionTime,
                    topLineStyle: topLine,
                    bottomLineStyle: bottomLine,
                    isGetOff: false
                )
                courseDetailStack.addArrangedSubview(stepView)
                
            case .bus, .subway:
                // 승차
                if let start = leg.start,
                   let startName = start.name,
                   let end = leg.end,
                   let endName = end.name {
                    
                    let startIcon = UIImage(named: leg.mode == .bus
                                            ? busIcon[leg.type ?? "0"] ?? busDefaultIcon
                                            : subwayIcon[leg.type ?? "0"] ?? subwayDefaultIcon)
                    
                    let startStepView = CourseStepView()
                    startStepView.configure(
                        icon: startIcon,
                        title: leg.mode == .bus ? "\(startName) 승차" : "\(startName)역 승차",
                        time: nil,
                        topLineStyle: topLine,
                        bottomLineStyle: .solid,
                        isGetOff: false
                    )
                    courseDetailStack.addArrangedSubview(startStepView)
                    
                    // 하차
                    let isLastLeg = index == course.legs.count - 1
                    let endStepView = CourseStepView()
                    
                    let getOffIcon = UIImage(named: leg.mode == .bus
                                             ? busGetOffIcon[leg.type ?? "0"] ?? defaultGetOffIcon
                                             : subwayGetOffIcon[leg.type ?? "0"] ?? defaultGetOffIcon)
                    
                    // 하차 아이콘은 걷기로 연결될 수 있으므로 bottomLine 스타일
                    let endBottomLine: LineStyle = isLastLeg
                    ? .none
                    : (nextLeg?.mode == .walk ? .dotted : .solid)
                    
                    endStepView.configure(
                        icon: getOffIcon,
                        title: leg.mode == .bus ? "\(endName) 하차" : "\(endName)역 하차",
                        time: nil,
                        topLineStyle: .solid,
                        bottomLineStyle: endBottomLine,
                        isGetOff: true
                    )
                    courseDetailStack.addArrangedSubview(endStepView)
                }
                
//            case .unknown:
            default:
                let stepView = CourseStepView()
                stepView.configure(
                    icon: UIImage.walkGray700,
                    title: "알 수 없음",
                    time: nil,
                    topLineStyle: topLine,
                    bottomLineStyle: bottomLine,
                    isGetOff: false
                )
                courseDetailStack.addArrangedSubview(stepView)
            }
        }
    }
    
    private func setupGesture() {
        detailTapGesture.addTarget(self, action: #selector(detailTapped))
        detailStack.isUserInteractionEnabled = true
        detailStack.addGestureRecognizer(detailTapGesture)
        
        courseTapGesture.addTarget(self, action: #selector(toggleCourseDetail))
        courseDownButton.isUserInteractionEnabled = true
        courseDownButton.addGestureRecognizer(courseTapGesture)
    }
    
    // MARK: - Course Detail View Handler
    @objc private func detailTapped() {
        onDetailTapped?()
    }
    
    // MARK: - Course Detail Toggle Handler
    @objc private func toggleCourseDetail() {
        onToggleExpanded?()
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
        
        return section
    }
}

