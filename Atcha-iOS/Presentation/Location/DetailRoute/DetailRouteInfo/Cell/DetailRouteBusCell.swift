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
    
    // MARK: Departure UI
    private let busIconContainerView: UIView = UIView()
    private let busIconImageView = UIImageView()
    private let startLabel: UILabel = UILabel()
    private let timeStarBadgeLabel: TimeBadgeLabel = TimeBadgeLabel()
    private lazy var startStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [timeStarBadgeLabel, busIconContainerView, startLabel])
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
    
    // MARK: - Bus Info
    private let busBadgeView: BusBadgeView = BusBadgeView()
    private let stationListStackView = UIStackView()
    
    private let busTimerFirstLabel: UILabel = UILabel()
//    private let busTimerSecondLabel: UILabel = UILabel()
    private lazy var busTimerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [busTimerFirstLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }()
    
    private let remainigTimeLabel: UILabel = UILabel()
    
    // MARK: - Summary
    private let summaryView: DetailRouteSummaryView = DetailRouteSummaryView()
    
    private var stationInfos: [PassStopList] = []
    private var isExpanded: Bool = false
    var didTapSummary: (() -> Void)?
    var didTapDetail: (() -> Void)?
    var getNewBusRealTime: (() -> Void)?
    
    private var stationListStackViewTopConstraint: Constraint?
    private var stationListStackViewBottomConstraint: Constraint?
    private var endLabelTopConstraintWithoutStack: Constraint?
    
    // MARK: Timer
    var countdownTimer: Timer?
    var reloadTimer: Timer?
    
    var currentLegTrafficInfo: LegTrafficInfo? = nil
    var currentBusInfo: [RealTimeBusArrival] = []
    
    private var isArrivedEffectOn = false
    private var isAlarmFired: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupInitialConstraintState()
        setupAction()
        contentView.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 수정 1: prepareForReuse에서 constraint 상태 리셋 추가
    override func prepareForReuse() {
        super.prepareForReuse()
        
        animationView.isHidden = true
        animationView.stopAnimation()
        backgroundColor = .clear
        
        isExpanded = false
        stationListStackView.isHidden = true
        stationListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        stationListStackViewTopConstraint?.isActive = false
        stationListStackViewBottomConstraint?.isActive = false
        endLabelTopConstraintWithoutStack?.isActive = true
        
        isAlarmFired = false
        busTimerStackView.isHidden = true
    }
    
    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        setNeedsLayout()
        layoutIfNeeded()
        
        let targetSize = CGSize(
            width: layoutAttributes.frame.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        let size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let newAttributes = layoutAttributes
        newAttributes.frame.size.height = ceil(size.height)
        return newAttributes
    }
    
    private func setupUI() {
        circleContainerView.addSubview(circleView)
        busIconContainerView.addSubViews(animationView, busIconImageView)
        stickContainerView.addSubview(stickView)
        
        contentView.addSubViews(lineImageView,
                                busTimerStackView,
                                stickContainerView,
                                startStackView,
                                endStackView,
                                busBadgeView,
                                summaryView,
                                stationListStackView)
        
        lineImageView.image = UIImage.dotLine
        animationView.isHidden = true
        
        stickContainerView.backgroundColor = .clear
        circleContainerView.backgroundColor = .clear
        busIconContainerView.backgroundColor = .clear
        
        busIconImageView.contentMode = .scaleAspectFit
        circleView.setCornerRadius(8)
        
        stationListStackView.axis = .vertical
        stationListStackView.spacing = 10
        stationListStackView.isHidden = true
    }
    
    private func setupInitialConstraintState() {
        stationListStackViewTopConstraint?.isActive = false
        stationListStackViewBottomConstraint?.isActive = false
        endLabelTopConstraintWithoutStack?.isActive = true
    }
    
    private func setupLineImageView() {
        lineImageView.snp.makeConstraints { make in
            make.centerX.equalTo(stickContainerView.snp.centerX)
            make.bottom.equalToSuperview().inset(-12)
            make.width.equalTo(4)
        }
    }
    
    private func setupDepartureConstraints() {
        busIconImageView.snp.makeConstraints { make in
            make.size.equalTo(36)
            make.edges.equalToSuperview()
        }
        busIconContainerView.snp.makeConstraints { make in
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
            make.top.equalTo(busIconContainerView.snp.bottom).inset(20)
            make.bottom.equalTo(circleContainerView.snp.top).inset(20)
            make.centerX.equalTo(circleContainerView.snp.centerX)
        }
        stickView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.verticalEdges.equalToSuperview()
        }
    }
    
    // DetailRouteBusCell.swift
    
    private func setupInfoConstrains() {
        busBadgeView.snp.makeConstraints { make in
            make.leading.equalTo(startLabel.snp.leading)
            make.top.equalTo(startStackView.snp.bottom).offset(8)
        }
        
        summaryView.snp.makeConstraints { make in
            make.leading.equalTo(startLabel.snp.leading)
            make.top.equalTo(busBadgeView.snp.bottom).offset(16)
        }
        
        busTimerStackView.snp.makeConstraints { make in
            make.leading.equalTo(busBadgeView.snp.trailing).offset(8)
            make.centerY.equalTo(busBadgeView)
        }
        
        stationListStackView.snp.makeConstraints {
            $0.leading.equalTo(startLabel)
            stationListStackViewTopConstraint = $0.top
                .equalTo(summaryView.snp.bottom)
                .offset(16)
                .constraint
            stationListStackViewBottomConstraint = $0.bottom
                .equalTo(endStackView.snp.top)  // ← endLabel 대신 endStackView 기준으로 변경
                .offset(-28)
                .priority(.high)
                .constraint
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
            endLabelTopConstraintWithoutStack = make.top
                .equalTo(summaryView.snp.bottom)
                .offset(36)
                .priority(.high)
                .constraint
            make.horizontalEdges.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().priority(.high)
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
    
    func configure(info: LegTrafficInfo?, isAlarmFired: Bool) {
        self.isAlarmFired = isAlarmFired
        currentLegTrafficInfo = info
        
        stationInfos = []
        guard let info = info,
              let passStopList = info.passStopList,
              let firstStation = passStopList.first,
              let lastStation = passStopList.last,
              let sectionTime = info.sectionTime else { return }
        
        if isCurrentTimeBetween(startTime: info.startTime, endTime: info.endTime) {
            isNowUserLocationArrived()
        }
        
        timeStarBadgeLabel.setText(info.startTime)
        timeEndBadgeLabel.setText(info.endTime)
        
        stationInfos = passStopList
        busIconImageView.image = info.mode?.getIcon(for: info.type ?? "")
        stickView.backgroundColor = info.mode?.getColor(for: info.type ?? "")
        circleView.backgroundColor = info.mode?.getColor(for: info.type ?? "")
        busBadgeView.configure(number: info.busName,
                               color: info.mode?.getColor(for: info.type ?? ""))
        summaryView.configure(duration: sectionTime, stops: passStopList.count)
        addStationNameLabel(info: stationInfos)
        
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
        
        self.busTimerStackView.isHidden = !isAlarmFired
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
        if isArrivedEffectOn { return }
        isArrivedEffectOn = true
        animationView.isHidden = false
        animationView.startAnimationIfNeeded(forceRestart: true)
        backgroundColor = UIColor.opacity100
    }

    func stopArrivedEffectIfNeeded() {
        guard isArrivedEffectOn else { return }
        isArrivedEffectOn = false
        animationView.stopAnimation()
        animationView.isHidden = true
        backgroundColor = .clear
    }
}

// MARK: Action
extension DetailRouteBusCell {
    private func setupAction() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSummaryButton))
        summaryView.addGestureRecognizer(tapGesture)
        
        let busTap = UITapGestureRecognizer(target: self, action: #selector(handleBusBackTapped))
        busBadgeView.addGestureRecognizer(busTap)
    }
    
    @objc private func handleSummaryButton() {
        isExpanded.toggle()
        
        if isExpanded {
            endLabelTopConstraintWithoutStack?.isActive = false
            stationListStackViewTopConstraint?.isActive = true
            stationListStackViewBottomConstraint?.isActive = true
        } else {
            stationListStackViewTopConstraint?.isActive = false
            stationListStackViewBottomConstraint?.isActive = false
            endLabelTopConstraintWithoutStack?.isActive = true
        }
        
        stationListStackView.isHidden = !isExpanded
        stationListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        addStationNameLabel(info: stationInfos)
        
        self.contentView.setNeedsLayout()
        self.contentView.layoutIfNeeded()
        
        didTapSummary?()  // ← 이 안에서 applySnapshot() 호출됨
    }
    
    @objc private func handleBusBackTapped() {
        didTapDetail?()
    }
}

extension DetailRouteBusCell {
    func cleanRouteName(_ fullName: String?) -> String? {
        guard let fullName = fullName else { return nil }
        return fullName.components(separatedBy: ":").last
    }
    
    func doesIncludeBus(route1: String?, route2: String?) -> Bool {
        guard let cleaned1 = cleanRouteName(route1),
              let cleaned2 = cleanRouteName(route2) else { return false }
        return cleaned1 == cleaned2
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
}

// MARK: - Bus Realtime

extension DetailRouteBusCell {
    func setupBusRealTimeInfo(info: LegTrafficInfo?, busInfo: [RealTimeBusArrival]) {
        busTimerStackView.isHidden = false

        let filtered = busInfo
            .filter { ($0.remainingTime ?? -1) > 0 }

        currentBusInfo = filtered

        guard !busInfo.isEmpty else {
            stopCountdownTimer()
            busTimerFirstLabel.attributedText = AtchaFont.B6_R_14("", color: .gray300)
            return
        }

        guard !currentBusInfo.isEmpty else {
            stopCountdownTimer()
            busTimerFirstLabel.attributedText = AtchaFont.B6_R_14("", color: .widearea)
            return
        }

        updateBusTimerLabels()
        startCountdownTimerIfNeeded()
    }

    private func startCountdownTimerIfNeeded() {
        // 이미 돌고 있으면 유지
        if countdownTimer != nil { return }

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.decrementRemainingTime()
        }

        // 스크롤 중에도 잘 돌게 common mode 추천
        if let timer = countdownTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    // 1초마다 감소
    private func decrementRemainingTime() {
        guard !currentBusInfo.isEmpty else {
            stopCountdownTimer()
            return
        }

        for i in 0..<currentBusInfo.count {
            guard let time = currentBusInfo[i].remainingTime else { continue }
            currentBusInfo[i].remainingTime = time - 1
        }

        currentBusInfo = currentBusInfo.filter { ($0.remainingTime ?? -1) > 0 }

        if currentBusInfo.isEmpty {
            stopCountdownTimer()
            busTimerFirstLabel.attributedText = AtchaFont.B6_R_14("도착 또는 출발", color: .widearea)
//            busTimerSecondLabel.text = ""
            return
        }

        updateBusTimerLabels()
    }

    private func updateBusTimerLabels() {

        guard isAlarmFired else {
            busTimerStackView.isHidden = true
            return
        }
        
        busTimerStackView.isHidden = false
        
        func labelText(for info: RealTimeBusArrival) -> NSAttributedString {
            if info.busStatus == .end {
                return AtchaFont.B6_R_14("운행 종료", color: .gray)
            }

            guard let remaining = info.remainingTime else {
                return AtchaFont.B6_R_14("", color: .gray300)
            }

            if remaining <= 120 {
                return AtchaFont.B6_R_14("곧 도착", color: .widearea)
            } else {
                return AtchaFont.B6_R_14(formatSecondsToHMS(remaining), color: .widearea)
            }
        }

        switch currentBusInfo.count {
        case 2:
            busTimerFirstLabel.attributedText = labelText(for: currentBusInfo[0])
//            busTimerSecondLabel.attributedText = labelText(for: currentBusInfo[1])
        case 1:
            busTimerFirstLabel.attributedText = labelText(for: currentBusInfo[0])
//            busTimerSecondLabel.text = ""
        default:
            // 3개 이상이면 우선 2개만 보여주거나, 숨기지 말고 2개만 보여주자
            busTimerFirstLabel.attributedText = labelText(for: currentBusInfo[0])
//            busTimerSecondLabel.attributedText = labelText(for: currentBusInfo[1])
        }
    }

    private func formatSecondsToHMS(_ seconds: Int?) -> String {
        guard let seconds, seconds >= 0 else { return "" }

        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60

        if h > 0 {
            // 시가 있으면 시/분/초
            // (원하면 "1시간 0분 5초"처럼 0분도 보여줄지 결정 가능)
            if m > 0 {
                return "\(h)시간 \(m)분 \(s)초"
            } else {
                return "\(h)시간 \(s)초"
            }
        }

        if m > 0 {
            // 시가 없으면 분/초
            return "\(m)분 \(s)초"
        }

        // 분도 없으면 초만
        return "\(s)초"
    }
}
