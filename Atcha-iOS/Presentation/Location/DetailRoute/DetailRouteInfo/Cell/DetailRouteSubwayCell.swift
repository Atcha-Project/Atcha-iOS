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
    
    // MARK: Departure UI
    private let subwayIconContainerView: UIView = UIView()
    private let subwayIconImageView = UIImageView()
    private let startLabel: UILabel = UILabel()
    private let timeStarBadgeLabel: TimeBadgeLabel = TimeBadgeLabel()
    private lazy var startStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [timeStarBadgeLabel, subwayIconContainerView, startLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 5
        return stack
    }()
    
    private let lineImageView: UIImageView = UIImageView()
    private let animationView: DetailRouteAnimationView = DetailRouteAnimationView()
    
    // MARK: Arrival UI
    private let circleContainerView = UIView()
    private let circleView: UIView = UIView()
    private let endLabel: UILabel = UILabel()
    private let timeEndBadgeLabel: TimeBadgeLabel = TimeBadgeLabel()
    private lazy var endStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [timeEndBadgeLabel, circleContainerView, endLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 5
        return stack
    }()
    
    // MARK: StickView
    private let stickContainerView = UIView()
    private let stickView = UIView()
    
    // MARK: - Subway Info
    private let subwayBadgeLabel: UILabel = UILabel()
    private let summaryView: DetailRouteSummaryView = DetailRouteSummaryView()
    private let stationListStackView = UIStackView()
    
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
        setupInitialConstraintState()
        setupAction()
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
        circleContainerView.addSubview(circleView)
        subwayIconContainerView.addSubViews(animationView, subwayIconImageView)
        stickContainerView.addSubview(stickView)
        
        subwayIconImageView.contentMode = .scaleAspectFill
        circleView.setCornerRadius(8)
        
        contentView.addSubViews(lineImageView,
                                stickContainerView,
                                startStackView,
                                endStackView,
                                subwayBadgeLabel,
                                summaryView,
                                stationListStackView)
        
        lineImageView.image = UIImage.dotLine
        animationView.isHidden = true
        
        stickContainerView.backgroundColor = .clear
        circleContainerView.backgroundColor = .clear
        subwayIconContainerView.backgroundColor = .clear
        
        subwayIconImageView.contentMode = .scaleAspectFit
        circleView.setCornerRadius(8)
        
        stationListStackView.axis = .vertical
        stationListStackView.spacing = 10
        stationListStackView.isHidden = true
    }
    
    private func setupInitialConstraintState() {
        stationListStackViewTopConstraint?.isActive = false
        stationListStackViewBottomConstraint?.isActive = false
        endLabelTopConstraintWithoutStack?.isActive = true // ✅ isExpanded = false 상태
    }
    
    private func setupLineImageView() {
        lineImageView.snp.makeConstraints { make in
            make.centerX.equalTo(stickContainerView.snp.centerX)
            make.bottom.equalToSuperview().inset(-12)
            make.width.equalTo(4)
        }
    }
    
    private func setupDepartureConstraints() {
        subwayIconImageView.snp.makeConstraints { make in
            make.size.equalTo(36)
            make.edges.equalToSuperview()
        }
        subwayIconContainerView.snp.makeConstraints { make in
            make.size.equalTo(36)
        }
        
        animationView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        startStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().offset(16)
            make.top.equalToSuperview()
            make.height.equalTo(36)
        }
    }
    
    private func setupStickConstrains() {
        stickContainerView.snp.makeConstraints { make in
            make.width.equalTo(36)
            make.top.equalTo(subwayIconContainerView.snp.bottom).inset(20)
            make.bottom.equalTo(circleContainerView.snp.top).inset(20)
            make.centerX.equalTo(circleContainerView.snp.centerX)
        }
        stickView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.verticalEdges.equalToSuperview()
        }
    }
    
    private func setupInfoConstrains() {
        subwayBadgeLabel.snp.makeConstraints { make in
            make.leading.equalTo(startLabel.snp.leading)
            make.top.equalTo(startStackView.snp.bottom).offset(8)
        }
        
        summaryView.snp.makeConstraints { make in
            make.leading.equalTo(startLabel.snp.leading)
            make.top.equalTo(subwayBadgeLabel.snp.bottom).offset(16)
        }
        
        stationListStackView.snp.makeConstraints {
            $0.leading.equalTo(startLabel)
            stationListStackViewTopConstraint = $0.top.equalTo(summaryView.snp.bottom).offset(16).constraint
            stationListStackViewBottomConstraint = $0.bottom.equalTo(endLabel.snp.top).offset(-28).constraint
        }
    }
    
    private func setupArrivalConstraints() {
        circleContainerView.snp.makeConstraints { make in
            make.size.equalTo(36)
        }
        circleView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(10)
        }
        endStackView.snp.makeConstraints { make in
            endLabelTopConstraintWithoutStack = make.top.equalTo(summaryView.snp.bottom).offset(36).constraint
            make.horizontalEdges.equalToSuperview().offset(16)
            make.bottom.equalToSuperview()
            make.height.equalTo(36)
        }
    }
    
    private func setupConstraints() {
        setupLineImageView()
        setupDepartureConstraints()
        setupStickConstrains()
        setupInfoConstrains()
        setupArrivalConstraints()
    }
    
    func configure(info: LegTrafficInfo?) {
        stationInfos = []
        guard let info = info,
              let passStopList = info.passStopList,
              let firstStation = passStopList.first,
              let lastStation = passStopList.last,
              let sectionTime = info.sectionTime else { return }
        
        stationInfos = passStopList
        timeStarBadgeLabel.setText(info.startTime)
        timeEndBadgeLabel.setText(info.endTime)
        
        subwayIconImageView.image = info.mode?.getIcon(for: info.type ?? "")
        stickView.backgroundColor = info.mode?.getColor(for: info.type ?? "")
        circleView.backgroundColor = info.mode?.getColor(for: info.type ?? "")
        //        subwayBadgeLabel.configure(number: info.busName,
        //                               color: info.mode?.getColor(for: info.type ?? ""))
        summaryView.configure(duration: sectionTime, stops: passStopList.count)
        addStationNameLabel(info: stationInfos)
        
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
        
        if isCurrentTimeBetween(startTime: info.startTime, endTime: info.endTime) {
            isNowUserLocationArrived()
        }
    }
    
    private func addStationNameLabel(info: [PassStopList]) {
        info.dropFirst().dropLast().forEach { list in
            let label = UILabel()
            label.attributedText = AtchaFont.B4_R_15(list.stationName ?? "", color: .gray200)
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
            stationListStackView.addArrangedSubview(label)
        }
    }
    
    func isNowUserLocationArrived() {
        // 해당시간에 들어와야 애니메이션 실행 합니다.
        animationView.isHidden = false
        animationView.startAnimationIfNeeded(forceRestart: true)
        backgroundColor = UIColor.opacity100
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
}

// MARK: Action
extension DetailRouteSubwayCell {
    private func setupAction() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSummaryButton))
        summaryView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleSummaryButton() {
        isExpanded.toggle()
        stationListStackView.isHidden = !isExpanded

        stationListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        addStationNameLabel(info: stationInfos)

        stationListStackViewTopConstraint?.isActive = isExpanded
        stationListStackViewBottomConstraint?.isActive = isExpanded
        endLabelTopConstraintWithoutStack?.isActive = !isExpanded
        layoutIfNeeded()

        didTapSummary?()
    }
}
