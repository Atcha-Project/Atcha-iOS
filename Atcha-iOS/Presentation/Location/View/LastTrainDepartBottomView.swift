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
    
    let actionPublisher = PassthroughSubject<Action, Never>()
    
    private let titleView: UIView = UIView()
//    ·
    private let trainIconImageView: UIImageView = UIImageView()
    private let trainTimeLabel: UILabel = UILabel()
    private let trainRigtImageView: UIImageView = UIImageView()
    private let trainRemainStationLabel: UILabel = UILabel()
    private let reloadImageView: UIImageView = UIImageView()
    private lazy var trainStackView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [trainIconImageView, trainTimeLabel, trainRemainStationLabel, trainRigtImageView, reloadImageView])
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        return stackView
    }()
    
    
    
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
        timeView.addSubViews(hourLabel, hourTimeLabel, miniuteLabel, minuteTimeLabel)
        addSubViews(trainStackView, timeView, locationLabel, buttonStackView)
        
        trainRigtImageView.image = UIImage.infoOutlined
        trainRigtImageView.contentMode = .scaleAspectFit
        trainRigtImageView.tintColor = .gray500
        
        reloadImageView.image = UIImage.refreshOutlined
        reloadImageView.contentMode = .scaleAspectFit
        reloadImageView.tintColor = .white
        reloadImageView.setContentHuggingPriority(.required, for: .horizontal)
        
        trainTimeLabel.attributedText = AtchaFont.B4_R_15("출발시간", color: .white)
        
        exitButton.setContentHuggingPriority(.required, for: .horizontal)
        exitButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        detailRoadMapButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailRoadMapButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    private func setupAutoLayout() {
        trainStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(24)
            make.height.equalTo(28)
        }
        
        timeView.snp.makeConstraints { make in
            make.height.equalTo(66)
            make.top.equalTo(trainStackView.snp.bottom)
            make.horizontalEdges.equalToSuperview().inset(16)
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

// MARK: Binding Leg Info
extension LastTrainDepartBottomView {
    func setupLegInfo(info: LegInfo) {
        guard let departureString = info.pathInfo.first?.departureDateTime else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = .current
        
        if let departureDate = formatter.date(from: departureString) {
            //            if departureDate > Date() {
            if departureDate <= Date() {
                print("출발 시간이 미래입니다.")
                if let (hour, minute) = departureString.toHourMinute() {
                    hourLabel.attributedText = AtchaFont.B1_R_17("시", color: .white)
                    miniuteLabel.attributedText = AtchaFont.B1_R_17("분", color: .white)
                    hourTimeLabel.attributedText = AtchaFont.D2_EB_48(hour, color: .white)
                    minuteTimeLabel.attributedText = AtchaFont.D2_EB_48(minute, color: .white)
                }
            } else {
                if let firstNonWalkMode = info.pathInfo.first(where: { $0.mode != .walk }) {
                    print("최초의 walk 제외 mode: \(firstNonWalkMode.mode?.rawValue ?? "없음")")
                    switch firstNonWalkMode.mode {
                    case .bus:
                        let busDetailInfo = info.busInfo.filter { $0.routeName?.isEmpty == false }
                        if let firstValidInfo = busDetailInfo.first(where: { $0.routeName != nil }) {
                            let request = BusRealTimeInfoRequest(
                                routeName: firstValidInfo.routeName,
                                stationName: firstValidInfo.start?.name,
                                lat: firstValidInfo.start?.lat,
                                lon: firstValidInfo.start?.lon,
                                passStations: firstValidInfo.passStations
                            )
                        }
                    case .subway:
                        if let departureDate = formatter.date(from: departureString) {
                            let now = Date()
                            let interval = departureDate.timeIntervalSince(now)
                            
                            let minutes = Int(interval / 60)
                            let seconds = Int(interval.truncatingRemainder(dividingBy: 60))
                            
                            hourLabel.attributedText = AtchaFont.B1_R_17("분", color: .widearea)
                            miniuteLabel.attributedText = AtchaFont.B1_R_17("초", color: .widearea)
                            hourTimeLabel.attributedText = AtchaFont.D2_EB_48("\(minutes)", color: .widearea)
                            minuteTimeLabel.attributedText = AtchaFont.D2_EB_48("\(seconds)", color: .widearea)
                            
                            if let firstSubwayLeg = info.trafficInfo.first(where: { $0.mode == .subway }),
                               let firstStationName = firstSubwayLeg.passStopList?.first?.stationName {
                                trainRigtImageView.isHidden = true
                                trainIconImageView.image = UIImage.route16PxSubway
                                trainIconImageView.tintColor = firstSubwayLeg.mode?.getColor(for: firstSubwayLeg.type ?? "")
                                trainTimeLabel.attributedText = AtchaFont.B4_R_15("\(firstStationName)역", color: .white)
                            }
                        }
                    default: do {}
                    }
                }
            }
        }
    }
}

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
