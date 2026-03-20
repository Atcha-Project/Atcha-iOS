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
    
    private let subwayDirectionLabel = UILabel()
    private let subwayTimerLabel = UILabel()
    private lazy var subwayRealtimeStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [subwayDirectionLabel, subwayTimerLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()
    
    private var subwayCountdownTimer: Timer?
    private var currentRemainingSec: Int?
    
    var currentLegTrafficInfo: LegTrafficInfo? = nil
    private var isArrivedEffectOn = false
    private var isAlarmFired: Bool = false
    private var hasMetZero: Bool = false
    private var isBoarded: Bool = false
    private var hasDepartedStartStation: Bool = false
    
    
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
        
        isExpanded = false
        stationListStackView.isHidden = true
        stationListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        stationListStackViewTopConstraint?.isActive = false
        stationListStackViewBottomConstraint?.isActive = false
        endLabelTopConstraintWithoutStack?.isActive = true
        
        subwayDirectionLabel.text = nil
        subwayTimerLabel.text = nil
        subwayCountdownTimer?.invalidate()
        subwayCountdownTimer = nil
        currentRemainingSec = nil
        isAlarmFired = false
        subwayTimerLabel.isHidden = true
        
        hasMetZero = false
        isBoarded = false
        hasDepartedStartStation = false
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
        subwayIconContainerView.addSubViews(animationView, subwayIconImageView)
        stickContainerView.addSubview(stickView)
        
        subwayIconImageView.contentMode = .scaleAspectFill
        circleView.setCornerRadius(8)
        
        contentView.addSubViews(lineImageView,
                                stickContainerView,
                                startStackView,
                                endStackView,
                                subwayRealtimeStackView,
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
        
        subwayDirectionLabel.numberOfLines = 1
        subwayTimerLabel.numberOfLines = 1
        
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
        //        subwayBadgeLabel.snp.makeConstraints { make in
        //            make.leading.equalTo(startLabel.snp.leading)
        //            make.top.equalTo(startStackView.snp.bottom).offset(8)
        //        }
        
        subwayRealtimeStackView.snp.makeConstraints { make in
            make.leading.equalTo(startLabel.snp.leading)
            make.top.equalTo(startStackView.snp.bottom).offset(8)
        }
        
        summaryView.snp.makeConstraints { make in
            make.leading.equalTo(startLabel.snp.leading)
            make.top.equalTo(subwayRealtimeStackView.snp.bottom).offset(16)
        }
        
        stationListStackView.snp.makeConstraints {
            $0.leading.equalTo(startLabel)
            stationListStackViewTopConstraint = $0.top
                .equalTo(summaryView.snp.bottom)
                .offset(16)
                .constraint
            
            stationListStackViewBottomConstraint = $0.bottom
                .equalTo(endStackView.snp.top)
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
                .priority(.high)  // ✅ high 우선순위
                .constraint
            make.horizontalEdges.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().priority(.high)  // ✅ high 우선순위
            make.height.equalTo(36)
        }
        
        endLabelTopConstraintWithoutStack?.isActive = false
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
        
        //        if isCurrentTimeBetween(startTime: info.startTime, endTime: info.endTime) {
        //            isNowUserLocationArrived()updateSubwayTimerLabel
        //        }
        
        self.subwayTimerLabel.isHidden = !isAlarmFired
        if isAlarmFired && currentRemainingSec != nil {
            updateSubwayTimerLabel()
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
    
    func isNowUserLocationArrived(hasDeparted: Bool = false) {
        if hasDeparted && hasMetZero {
            self.hasDepartedStartStation = true
        }
        
        if isArrivedEffectOn {
            // 출발 상태가 들어왔다면 라벨 갱신 (탑승 완료 띄우기)
            if self.hasDepartedStartStation { updateSubwayTimerLabel() }
            return
        }
        
        isArrivedEffectOn = true
        animationView.isHidden = false
        animationView.startAnimationIfNeeded(forceRestart: true)
        backgroundColor = UIColor.opacity100
        
        updateSubwayTimerLabel()
    }
    
    func stopArrivedEffectIfNeeded() {
        guard isArrivedEffectOn else { return }
        isArrivedEffectOn = false
        animationView.stopAnimation()
        animationView.isHidden = true
        backgroundColor = .clear
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
        
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
        
        didTapSummary?()
    }
}

extension DetailRouteSubwayCell {
    
    func setupSubwayRealTime(routeName: String?, infos: [SubwayRealTimeInfo]) {
        stopSubwayCountdownTimer()
        currentRemainingSec = nil
        
        subwayTimerLabel.isHidden = false
        subwayDirectionLabel.attributedText = AtchaFont.B6_R_14("", color: .white)
        
        guard let routeName, !routeName.isEmpty else {
            subwayTimerLabel.attributedText = AtchaFont.B6_R_14("", color: .gray300)
            return
        }
        
        let key = routeName.components(separatedBy: ":").last ?? routeName
        
        let matched = infos.first { info in
            let apiRaw = info.routeName ?? ""
            let apiKey = apiRaw.components(separatedBy: ":").last ?? apiRaw
            return apiKey == key
        }
        
        guard let matched else {
            subwayDirectionLabel.attributedText = AtchaFont.B6_R_14("", color: .gray300)
            subwayTimerLabel.attributedText = AtchaFont.B6_R_14("", color: .gray300)
            return
        }
        
        if let destination = matched.destination, destination != "" {
            subwayDirectionLabel.attributedText = AtchaFont.B6_R_14("\(destination)행", color: .white)
        } else {
            subwayDirectionLabel.attributedText = AtchaFont.B6_R_14("", color: .white)
        }
        
        guard let sec = matched.remainingTime, sec >= 0 else {
            subwayTimerLabel.attributedText = AtchaFont.B6_R_14("", color: .widearea)
            return
        }
        
        currentRemainingSec = sec
        updateSubwayTimerLabel()
        startSubwayCountdownTimerIfNeeded()
    }
    
    private func startSubwayCountdownTimerIfNeeded() {
        if subwayCountdownTimer != nil { return }
        
        subwayCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.decrementSubwayRemainingTime()
        }
        
        if let timer = subwayCountdownTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopSubwayCountdownTimer() {
        subwayCountdownTimer?.invalidate()
        subwayCountdownTimer = nil
    }
    
    private func decrementSubwayRemainingTime() {
        guard let sec = currentRemainingSec else {
            stopSubwayCountdownTimer()
            return
        }
        
        // 무조건 1초씩 뺌 (음수 허용)
        let next = sec - 1
        currentRemainingSec = next
        
        updateSubwayTimerLabel() // 라벨 업데이트 (판정은 여기서 알아서 함)
        
        // 탑승 완료 자물쇠가 잠기면 타이머 정지
        if isBoarded { stopSubwayCountdownTimer() }
    }
    
    private func updateSubwayTimerLabel() {
        
        guard isAlarmFired else {
            subwayTimerLabel.isHidden = true
            return
        }
        
        subwayTimerLabel.isHidden = false
        
        if isBoarded {
            subwayTimerLabel.attributedText = AtchaFont.B6_R_14("탑승 완료", color: .gray300)
            return
        }
        
        guard let sec = currentRemainingSec else {
            if hasMetZero {
                isBoarded = true
                subwayTimerLabel.attributedText = AtchaFont.B6_R_14("탑승 완료", color: .gray300)
            } else {
                subwayTimerLabel.attributedText = AtchaFont.B6_R_14("", color: .widearea)
            }
            return
        }
        
        if sec <= 0 {
            hasMetZero = true
        }
        
        if hasMetZero {
            // (1) 역에서 150m 이상 멀어짐 (ViewModel에서 알려줌)
            // (2) 0초 도달 후 1분(-60초)이 경과함
            // (3) 아직 애니메이션 켜져 있는데 API가 다음 배차(sec > 0)로 갱신됨
            if self.hasDepartedStartStation || sec <= -60 || (sec > 0 && isArrivedEffectOn) {
                isBoarded = true // 자물쇠 딸깍
                subwayTimerLabel.attributedText = AtchaFont.B6_R_14("탑승 완료", color: .gray300)
                stopSubwayCountdownTimer() // 타이머 종료
                return
            }
        }
        
        if sec <= 0 {
            subwayTimerLabel.attributedText = AtchaFont.B6_R_14("도착 또는 출발", color: .widearea)
            return
        }
        
        if sec <= 120 {
            subwayTimerLabel.attributedText = AtchaFont.B6_R_14("곧 도착", color: .widearea)
            return
        }
        
        subwayTimerLabel.attributedText = AtchaFont.B6_R_14(formatSecondsToHMS(sec), color: .widearea)
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
