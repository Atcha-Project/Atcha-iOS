//
//  LastTrainRealTimeBottomView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 8/6/25.
//

import UIKit
import Combine

final class LastTrainRealTimeBottomView: UIView {
    enum Action {
        case reloadTapped
        case detailRoadMapTapped
        case exitTapped
        case refreshBusTime
        case finishAlarm
    }
    
    private var countdownCancellable: AnyCancellable?
    private var busRefreshCancellable: AnyCancellable?
    
    private var remainingTimeInSeconds: Int = 0
    
    let actionPublisher = PassthroughSubject<Action, Never>()
    
    private let titleView: UIView = UIView()
    private let iconImageView: UIImageView = UIImageView()
    private let trainInfoLabel: UILabel = UILabel()
    private let remainStationLabel: UILabel = UILabel()
    private let alreadySoonLabel: UILabel = UILabel()
    private let reloadImageView: UIImageView = UIImageView()
    
    private let timeView: UIView = UIView()
    private let minuteLabel: UILabel = UILabel()
    private let minuteTimeLabel: UILabel = UILabel()
    private let secondLabel: UILabel = UILabel()
    private let secondTimeLabel: UILabel = UILabel()
    
    private let locationLabel: UILabel = UILabel()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [exitButton, detailRoadMapButton])
        stackView.spacing = 12
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        return stackView
    }()
    private let exitButton: AtchaButton = AtchaButton(text: "종료",
                                                      size: .h48,
                                                      style: .line(.line))
    private let detailRoadMapButton: AtchaButton = AtchaButton(text: "상세 경로",
                                                               size: .h48,
                                                               style: .filled(.defaultGray),
                                                               image: UIImage.home16Px)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupAutoLayout()
        setupActions()
    }
    
    private func setupUI() {
        backgroundColor = .gray950
        layer.cornerRadius = 20
        titleView.addSubViews(iconImageView,
                              trainInfoLabel,
                              remainStationLabel,
                              reloadImageView)
        timeView.addSubViews(minuteLabel,
                             minuteTimeLabel,
                             secondLabel,
                             secondTimeLabel,
                             alreadySoonLabel)
        addSubViews(titleView,
                    timeView,
                    locationLabel,
                    buttonStackView)
        
        exitButton.setContentHuggingPriority(.required, for: .horizontal)
        exitButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        detailRoadMapButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailRoadMapButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        reloadImageView.image = UIImage.refreshOutlined
        reloadImageView.contentMode = .scaleAspectFit
        reloadImageView.tintColor = .white
        
        alreadySoonLabel.isHidden = true
        alreadySoonLabel.attributedText = AtchaFont.D2_EB_48("곧 도착", color: .widearea)
        
        minuteLabel.attributedText = AtchaFont.B1_R_17("분", color: .widearea)
        secondLabel.attributedText = AtchaFont.B1_R_17("초", color: .widearea)
    }
    
    private func setupAutoLayout() {
        titleView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(24)
            make.height.equalTo(28)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
            make.size.equalTo(16)
        }
        
        alreadySoonLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalTo(timeView.snp.centerY)
        }
        
        trainInfoLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconImageView.snp.trailing).offset(4)
            make.height.equalTo(20)
        }
        
        remainStationLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(trainInfoLabel.snp.trailing).offset(6)
            make.height.equalTo(20)
        }
        
        reloadImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.size.equalTo(28)
        }
        
        timeView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(20)
            make.top.equalTo(titleView.snp.bottom).inset(-4)
            make.height.equalTo(66)
        }
        
        minuteTimeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        minuteLabel.snp.makeConstraints { make in
            make.leading.equalTo(minuteTimeLabel.snp.trailing).offset(4)
            make.centerY.equalTo(minuteTimeLabel.snp.bottom).offset(-20)
        }
        
        secondTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(minuteLabel.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        
        secondLabel.snp.makeConstraints { make in
            make.leading.equalTo(secondTimeLabel.snp.trailing).offset(4)
            make.centerY.equalTo(secondTimeLabel.snp.bottom).offset(-20)
        }
        
        locationLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(20)
            make.top.equalTo(timeView.snp.bottom).offset(16)
        }
        
        buttonStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40)
            make.top.equalTo(locationLabel.snp.bottom).offset(16)
            make.height.equalTo(88)
        }
    }
    
    private func setupActions() {
        exitButton.addTarget(self, action: #selector(handleExitTapped), for: .touchUpInside)
        detailRoadMapButton.addTarget(self, action: #selector(handleDetailRoadTapped), for: .touchUpInside)
        reloadImageView.isUserInteractionEnabled = true
        reloadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleReloadTapped)))
    }
}

// MARK: Binding Leg Info
extension LastTrainRealTimeBottomView {
    func setupLegInfo(info: LegInfo) {
        guard let departureStr = info.pathInfo.first?.departureDateTime else { return }
        if let firstNonWalkMode = info.pathInfo.first(where: { $0.mode != .walk }) {
            switch firstNonWalkMode.mode {
            case .bus:
                let busDetailInfo = info.busInfo.filter { $0.routeName?.isEmpty == false }
                if let _ = busDetailInfo.first(where: { $0.routeName != nil }) {
                    actionPublisher.send(.refreshBusTime)
                    startBusAutoRefresh()
                }
                
                if let firstBusLeg = info.trafficInfo.first(where: { $0.mode == .bus }) {
                    iconImageView.image = UIImage.route16PxBus
                    iconImageView.tintColor = firstBusLeg.mode?.getColor(for: firstBusLeg.type ?? "")
                    trainInfoLabel.attributedText = AtchaFont.B4_R_15("\(firstBusLeg.busName ?? "")", color: .white)
                }
            case .subway:
                setupSubwayTime(departureStr: departureStr)
                if let firstSubwayLeg = info.trafficInfo.first(where: { $0.mode == .subway }),
                   let firstStationName = firstSubwayLeg.passStopList?.first?.stationName {
                    iconImageView.image = UIImage.route16PxSubway
                    iconImageView.tintColor = firstSubwayLeg.mode?.getColor(for: firstSubwayLeg.type ?? "")
                    trainInfoLabel.attributedText = AtchaFont.B4_R_15("\(firstStationName)역",
                                                                      color: .white)
                }
            default: do {}
            }
        }
    }
    
    private func setupSubwayTime(departureStr: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = .current
        
        if let departureDate = formatter.date(from: departureStr) {
            let now = Date()
            let interval = departureDate.timeIntervalSince(now)
            
            let minutes = Int(interval / 60)
            let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
            
            minuteTimeLabel.attributedText = AtchaFont.D2_EB_48("\(minutes)", color: .widearea)
            secondTimeLabel.attributedText = AtchaFont.D2_EB_48("\(seconds)", color: .widearea)
            //            reloadImageView.isHidden = true
            startCountdownWithCombine(minutes: minutes, seconds: seconds)
        }
    }
    
    func setupBusRealTime(realTime: BusRealTimeInfo?) {
        guard let realTime, let firstInfo = realTime.realTimeBusArrival?.first else { return }
        
        let time = firstInfo.remainingTime?.toHourMinuteStringFromSeconds
        let result = extractMinuteSecond(from: time)
        minuteTimeLabel.attributedText = AtchaFont.D2_EB_48("\(result.0)",
                                                            color: .widearea)
        secondTimeLabel.attributedText = AtchaFont.D2_EB_48("\(result.1)",
                                                            color: .widearea)
        
        startCountdownWithCombine(minutes: result.0, seconds: result.1)
        remainStationLabel.attributedText = AtchaFont.B4_R_15("· \(firstInfo.remainingStations ?? 0)정류장 전", color: .white)
    }
    
    private func extractMinuteSecond(from timeText: String?) -> (minute: Int, second: Int) {
        guard let timeText else { return (0, 0) }
        let regex = try! NSRegularExpression(pattern: "\\d+")
        let matches = regex.matches(in: timeText, range: NSRange(timeText.startIndex..., in: timeText))
        
        let numbers = matches.map {
            Int((timeText as NSString).substring(with: $0.range)) ?? 0
        }
        
        let minute = numbers.count > 0 ? numbers[0] : 0
        let second = numbers.count > 1 ? numbers[1] : 0
        
        print("minute : \(minute), second : \(second)")
        
        return (minute, second)
    }
}

extension LastTrainRealTimeBottomView {
    private func startCountdownWithCombine(minutes: Int, seconds: Int) {
        countdownCancellable?.cancel() // 기존 구독 해제
        remainingTimeInSeconds = minutes * 60 + seconds
        updateCountdownLabels()
        
        print("remainingTimeInSeconds : \(remainingTimeInSeconds)")
        
        self.minuteLabel.isHidden = false
        self.minuteTimeLabel.isHidden = false
        self.secondLabel.isHidden = false
        self.secondTimeLabel.isHidden = false
        self.alreadySoonLabel.isHidden = true
        
        countdownCancellable = Timer
            .publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.remainingTimeInSeconds -= 1
                
                if self.remainingTimeInSeconds <= 60 {
                    self.countdownCancellable?.cancel()
                    self.minuteLabel.isHidden = true
                    self.minuteTimeLabel.isHidden = true
                    self.secondLabel.isHidden = true
                    self.secondTimeLabel.isHidden = true
                    self.alreadySoonLabel.isHidden = false
                } else {
                    self.updateCountdownLabels()
                }
            }
    }
    
    private func updateCountdownLabels() {
        let minutes = remainingTimeInSeconds / 60
        let seconds = remainingTimeInSeconds % 60
        
        minuteTimeLabel.attributedText = AtchaFont.D2_EB_48("\(minutes)",
                                                            color: .widearea)
        secondTimeLabel.attributedText = AtchaFont.D2_EB_48("\(seconds)",
                                                            color: .widearea)
    }
    
    private func cancelCountdownTimer() {
        countdownCancellable?.cancel()
        countdownCancellable = nil
    }
    
    private func startBusAutoRefresh() {
        busRefreshCancellable?.cancel() // 기존 타이머 제거

        busRefreshCancellable = Timer
            .publish(every: 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.actionPublisher.send(.refreshBusTime)
            }
    }
}

extension LastTrainRealTimeBottomView {
    func setupLoaction(location: String?) {
        guard let location else { return }
        let title: String = "\(location) -> 우리집"
        locationLabel.attributedText = AtchaFont.B4_R_15(title, color: .gray300)
    }
}

extension LastTrainRealTimeBottomView {
    @objc private func handleExitTapped() {
        actionPublisher.send(.exitTapped)
    }
    
    @objc private func handleDetailRoadTapped() {
        actionPublisher.send(.detailRoadMapTapped)
    }
    
    @objc private func handleReloadTapped() {
        actionPublisher.send(.reloadTapped)
    }
}
