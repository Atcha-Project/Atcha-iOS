//
//  LastTrainDepartBottomView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/27/25.
//

import UIKit
import Combine

final class LastTrainDepartBottomView: UIView {
    enum Action {
        case reloadTapped
        case timeTapped
        case locationTapped
        case detailRoadMapTapped
        case exitTapped
    }
    
    private var countdownCancellable: AnyCancellable?
    private var remainingTimeInSeconds: Int = 0
    let actionPublisher = PassthroughSubject<Action, Never>()
    
    private let titleView: UIView = UIView()
    private let trainTimeLabel: UILabel = UILabel()
    private let trainRigtImageView: UIImageView = UIImageView()
    private let reloadImageView: UIImageView = UIImageView()
    
//    private let trainIconImageView: UIImageView = UIImageView()
//    private let trainTimeLabel: UILabel = UILabel()
//    private let trainRigtImageView: UIImageView = UIImageView()
//    private let trainRemainStationLabel: UILabel = UILabel()
//    private let alreadySoonLabel: UILabel = UILabel()
    
   
//    private lazy var trainStackView: UIStackView = {
//        let stackView: UIStackView = UIStackView(arrangedSubviews: [trainIconImageView, trainTimeLabel, trainRemainStationLabel, trainRigtImageView, reloadImageView])
//        stackView.axis = .horizontal
//        stackView.spacing = 6
//        stackView.alignment = .center
//        return stackView
//    }()
    
    private let timeView: UIView = UIView()
    private let hourTimeLabel: UILabel = UILabel()
    private let hourLabel: UILabel = UILabel()
    private let miniuteLabel: UILabel = UILabel()
    private let minuteTimeLabel: UILabel = UILabel()
    
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
        titleView.addSubViews(trainTimeLabel, trainRigtImageView, reloadImageView)
        timeView.addSubViews(hourLabel, hourTimeLabel, miniuteLabel, minuteTimeLabel)
        addSubViews(titleView, timeView, locationLabel, buttonStackView)
        
//        alreadySoonLabel.isHidden = true
//        alreadySoonLabel.attributedText = AtchaFont.D2_EB_48("곧 도착", color: .widearea)
//        
//        trainRigtImageView.image = UIImage.infoOutlined
//        trainRigtImageView.contentMode = .scaleAspectFit
//        trainRigtImageView.tintColor = .gray500
//        trainRigtImageView.setContentHuggingPriority(.required, for: .horizontal)
//        
//        trainRemainStationLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        trainTimeLabel.attributedText = AtchaFont.B4_R_15("출발시간", color: .white)
        trainRigtImageView.image = UIImage.infoOutlined
        trainRigtImageView.contentMode = .scaleAspectFit
        trainRigtImageView.tintColor = .gray500
//        trainRigtImageView.setContentHuggingPriority(.required, for: .horizontal)
        
        reloadImageView.image = UIImage.refreshOutlined
        reloadImageView.contentMode = .scaleAspectFit
        reloadImageView.tintColor = .white
        reloadImageView.setContentHuggingPriority(.required, for: .horizontal)
        
        hourLabel.attributedText = AtchaFont.B1_R_17("시", color: .white)
        miniuteLabel.attributedText = AtchaFont.B1_R_17("분", color: .white)
        
        
        
//        trainTimeLabel.setContentHuggingPriority(.required, for: .horizontal)
//        trainTimeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
//        trainTimeLabel.attributedText = AtchaFont.B4_R_15("출발시간", color: .white)
        
        exitButton.setContentHuggingPriority(.required, for: .horizontal)
        exitButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        detailRoadMapButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailRoadMapButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    private func setupAutoLayout() {
        titleView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(24)
            make.height.equalTo(28)
        }
        
        trainTimeLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview()
        }
        
        trainRigtImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(trainTimeLabel.snp.trailing).offset(6)
            make.size.equalTo(14)
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
        
        hourTimeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        hourLabel.snp.makeConstraints { make in
            make.leading.equalTo(hourTimeLabel.snp.trailing).offset(4)
            make.centerY.equalTo(hourTimeLabel.snp.bottom).offset(-20)
        }
        
        minuteTimeLabel.snp.makeConstraints { make in
            make.leading.equalTo(hourLabel.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        
        miniuteLabel.snp.makeConstraints { make in
            make.leading.equalTo(minuteTimeLabel.snp.trailing).offset(4)
            make.centerY.equalTo(minuteTimeLabel.snp.bottom).offset(-20)
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
        hourTimeLabel.isUserInteractionEnabled = true
        hourTimeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTimeTapped)))
        locationLabel.isUserInteractionEnabled = true
        locationLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLocationTapped)))
    }
    
    func setupLoaction(location: String?) {
        guard let location else { return }
        let title: String = "\(location) -> 우리집"
        locationLabel.attributedText = AtchaFont.B4_R_15(title, color: .gray300)
    }
}

// MARK: Timer
extension LastTrainDepartBottomView {
//    private func startCountdownWithCombine(minutes: Int, seconds: Int) {
//        countdownCancellable?.cancel() // 기존 구독 해제
//        remainingTimeInSeconds = minutes * 60 + seconds
//        
//        updateCountdownLabels()
//        
//        countdownCancellable = Timer
//            .publish(every: 1.0, on: .main, in: .common)
//            .autoconnect()
//            .sink { [weak self] _ in
//                guard let self = self else { return }
//                
//                self.remainingTimeInSeconds -= 1
//                
//                if self.remainingTimeInSeconds <= 120 {
//                    self.countdownCancellable?.cancel()
//                    self.hourLabel.isHidden = true
//                    self.miniuteLabel.isHidden = true
//                    self.hourTimeLabel.isHidden = true
//                    self.minuteTimeLabel.isHidden = true
//                    self.alreadySoonLabel.isHidden = false
//                } else {
//                    self.updateCountdownLabels()
//                }
//            }
//    }
    
//    private func updateCountdownLabels() {
//        let minutes = remainingTimeInSeconds / 60
//        let seconds = remainingTimeInSeconds % 60
//        
//        hourTimeLabel.attributedText = AtchaFont.D2_EB_48("\(minutes)", color: .widearea)
//        minuteTimeLabel.attributedText = AtchaFont.D2_EB_48("\(seconds)", color: .widearea)
//    }
//    
//    private func cancelCountdownTimer() {
//        countdownCancellable?.cancel()
//        countdownCancellable = nil
//    }
}

// MARK: Binding Leg Info
extension LastTrainDepartBottomView {
    func setupLegInfo(info: LegInfo) {
        guard let departureStr = info.pathInfo.first?.departureDateTime else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = .current
        
        if let _ = formatter.date(from: departureStr) {
            if let (hour, minute) = departureStr.toHourMinute() {
                hourTimeLabel.attributedText = AtchaFont.D2_EB_48(hour, color: .white)
                minuteTimeLabel.attributedText = AtchaFont.D2_EB_48(minute, color: .white)
            }
            
            //        guard let departureString = info.pathInfo.first?.departureDateTime else { return }
            //
            //        let formatter = DateFormatter()
            //        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            //        formatter.locale = .current
            //
            //        if let departureDate = formatter.date(from: departureString) {
            //            if departureDate > Date() {
            //                print("출발 시간이 미래입니다.")
            //                if let (hour, minute) = departureString.toHourMinute() {
            //                    hourLabel.attributedText = AtchaFont.B1_R_17("시", color: .white)
            //                    miniuteLabel.attributedText = AtchaFont.B1_R_17("분", color: .white)
            //                    hourTimeLabel.attributedText = AtchaFont.D2_EB_48(hour, color: .white)
            //                    minuteTimeLabel.attributedText = AtchaFont.D2_EB_48(minute, color: .white)
            //                    trainRigtImageView.isHidden = false
            //                    trainIconImageView.isHidden = true
            //                    trainRemainStationLabel.isHidden = true
            //                }
            //            } else {
            //                if let firstNonWalkMode = info.pathInfo.first(where: { $0.mode != .walk }) {
            //                    print("최초의 walk 제외 mode: \(firstNonWalkMode.mode?.rawValue ?? "없음")")
            //                    switch firstNonWalkMode.mode {
            //                    case .bus:
            //                        if let firstBusLeg = info.trafficInfo.first(where: { $0.mode == .bus }) {
            //                            trainRigtImageView.isHidden = true
            //                            trainIconImageView.image = UIImage.route16PxBus
            //                            trainIconImageView.tintColor = firstBusLeg.mode?.getColor(for: firstBusLeg.type ?? "")
            //                            trainTimeLabel.attributedText = AtchaFont.B4_R_15("\(firstBusLeg.busName ?? "")", color: .white)
            //                        }
            //
            //                        let busDetailInfo = info.busInfo.filter { $0.routeName?.isEmpty == false }
            //                        if let _ = busDetailInfo.first(where: { $0.routeName != nil }) {
            //                            handleReloadTapped()
            //                        }
            //                    case .subway:
            //                        if let departureDate = formatter.date(from: departureString) {
            //                            let now = Date()
            //                            let interval = departureDate.timeIntervalSince(now)
            //
            //                            let minutes = Int(interval / 60)
            //                            let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
            //
            //                            hourLabel.attributedText = AtchaFont.B1_R_17("분", color: .widearea)
            //                            miniuteLabel.attributedText = AtchaFont.B1_R_17("초", color: .widearea)
            //                            hourTimeLabel.attributedText = AtchaFont.D2_EB_48("\(minutes)", color: .widearea)
            //                            minuteTimeLabel.attributedText = AtchaFont.D2_EB_48("\(seconds)", color: .widearea)
            //                            reloadImageView.isHidden = true
            //
            //                            startCountdownWithCombine(minutes: minutes, seconds: seconds)
            //
            //                            if let firstSubwayLeg = info.trafficInfo.first(where: { $0.mode == .subway }),
            //                               let firstStationName = firstSubwayLeg.passStopList?.first?.stationName {
            //                                trainRigtImageView.isHidden = true
            //                                trainIconImageView.image = UIImage.route16PxSubway
            //                                trainIconImageView.tintColor = firstSubwayLeg.mode?.getColor(for: firstSubwayLeg.type ?? "")
            //                                trainTimeLabel.attributedText = AtchaFont.B4_R_15("\(firstStationName)역", color: .white)
            //                            }
            //                        }
            //                    default: do {}
            //                    }
            //                }
            //            }
        }
    }
}
    
//    func setupBusRealTime(realTime: BusRealTimeInfo?) {
//        guard let realTime, let firstInfo = realTime.realTimeBusArrival?.first else { return }
//        
//        let time = firstInfo.remainingTime?.toHourMinuteStringFromSeconds
//        let result = extractMinuteSecond(from: time)
//        hourLabel.attributedText = AtchaFont.B1_R_17("분", color: .widearea)
//        miniuteLabel.attributedText = AtchaFont.B1_R_17("초", color: .widearea)
//        hourTimeLabel.attributedText = AtchaFont.D2_EB_48("\(result.0)", color: .widearea)
//        minuteTimeLabel.attributedText = AtchaFont.D2_EB_48("\(result.1)", color: .widearea)
//        
//        startCountdownWithCombine(minutes: result.0, seconds: result.1)
//        
//        trainRemainStationLabel.attributedText = AtchaFont.B4_R_15("· \(firstInfo.remainingStations ?? 0)정류장 전", color: .white)
//    }
    
//    private func extractMinuteSecond(from timeText: String?) -> (minute: Int, second: Int) {
//        guard let timeText else { return (0, 0) }
//        let regex = try! NSRegularExpression(pattern: "\\d+")
//        let matches = regex.matches(in: timeText, range: NSRange(timeText.startIndex..., in: timeText))
//        
//        let numbers = matches.map {
//            Int((timeText as NSString).substring(with: $0.range)) ?? 0
//        }
//        
//        let minute = numbers.count > 0 ? numbers[0] : 0
//        let second = numbers.count > 1 ? numbers[1] : 0
//        
//        return (minute, second)
//    }
//}

extension LastTrainDepartBottomView {
    @objc private func handleExitTapped() {
        actionPublisher.send(.exitTapped)
    }
    
    @objc private func handleDetailRoadTapped() {
        actionPublisher.send(.detailRoadMapTapped)
    }
    
    @objc private func handleReloadTapped() {
        actionPublisher.send(.reloadTapped)
    }
    
    @objc private func handleTimeTapped() {
        actionPublisher.send(.timeTapped)
    }
    
    @objc private func handleLocationTapped() {
        actionPublisher.send(.locationTapped)
    }
}
