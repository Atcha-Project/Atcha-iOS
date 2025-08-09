//
//  LastTrainArrivalBottomView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 8/7/25.
//

import UIKit
import Combine

final class LastTrainArrivalBottomView: UIView {
    enum Action {
        case detailRoadMapTapped
        case exitTapped
    }
    
    private var finishTimer: Timer?
    let actionPublisher = PassthroughSubject<Action, Never>()
    
    private let titleView: UIView = UIView()
    private let trainTimeLabel: UILabel = UILabel()
    
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
        titleView.addSubViews(trainTimeLabel)
        timeView.addSubViews(hourLabel, hourTimeLabel, miniuteLabel, minuteTimeLabel)
        addSubViews(titleView, timeView, locationLabel, buttonStackView)
        
        trainTimeLabel.attributedText = AtchaFont.B4_R_15("우리집 도착시간", color: .white)
        
        hourLabel.attributedText = AtchaFont.B1_R_17("시", color: .white)
        miniuteLabel.attributedText = AtchaFont.B1_R_17("분", color: .white)
        
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
    }
    
    func setupLoaction(location: String?) {
        guard let location else { return }
        let title: String = "\(location) -> 우리집"
        locationLabel.attributedText = AtchaFont.B4_R_15(title, color: .gray300)
    }
}

// MARK: Timer
extension LastTrainArrivalBottomView {
    private func scheduleFinishAfter30min(from arrivalDate: Date) {
        // 이전 타이머 정리
        finishTimer?.invalidate()
        finishTimer = nil
        
        let elapsed = Date().timeIntervalSince(arrivalDate) // 초
//        let target: TimeInterval = 30 * 60                  // 30분 == 1800초
        let target: TimeInterval = 1 * 60                  // 30분 == 1800초
        let remaining = target - elapsed
        
        if remaining <= 0 {
            // 이미 30분 경과
            print("종료")
            return
        }
        
        finishTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
            print("종료")
            UserDefaultsWrapper.shared.remove(forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue)
            self?.actionPublisher.send(.exitTapped)
        }
    }
}

// MARK: Binding Leg Info
extension LastTrainArrivalBottomView {
    func setupLegInfo(info: LegInfo?) {
        
        guard let info, let departureStr = info.pathInfo.first?.departureDateTime,
              let totalTime = info.trafficInfo.first?.totalTime else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.locale = .current
        
        guard let departureDate = formatter.date(from: departureStr) else { return }
        
        let minutes = parseTotalTimeToMinutes(totalTime)
        
        guard let arrivalDate = Calendar.current.date(byAdding: .minute, value: minutes, to: departureDate) else { return }
        
        UserDefaultsWrapper.shared.set(arrivalDate, forKey: UserDefaultsWrapper.Key.arrivalTime.rawValue)
        
        let hour = Calendar.current.component(.hour, from: arrivalDate)
        let minute = Calendar.current.component(.minute, from: arrivalDate)
        
        let hourText = String(format: "%02d", hour)
        let minuteText = String(format: "%02d", minute)
        
        hourTimeLabel.attributedText = AtchaFont.D2_EB_48(hourText, color: .white)
        minuteTimeLabel.attributedText = AtchaFont.D2_EB_48(minuteText, color: .white)
        
        scheduleFinishAfter30min(from: arrivalDate)
    }
    
    private func parseTotalTimeToMinutes(_ time: String) -> Int {
        var totalMinutes = 0
        
        if let hourMatch = time.range(of: "\\d+(?=시간)", options: .regularExpression),
           let hour = Int(time[hourMatch]) {
            totalMinutes += hour * 60
        }
        
        if let minuteMatch = time.range(of: "\\d+(?=분)", options: .regularExpression),
           let minute = Int(time[minuteMatch]) {
            totalMinutes += minute
        }
        
        return totalMinutes
    }
}

extension LastTrainArrivalBottomView {
    @objc private func handleExitTapped() {
        actionPublisher.send(.exitTapped)
    }
    
    @objc private func handleDetailRoadTapped() {
        actionPublisher.send(.detailRoadMapTapped)
    }
}
