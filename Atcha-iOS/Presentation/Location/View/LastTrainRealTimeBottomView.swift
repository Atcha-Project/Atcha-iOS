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
        case locationTapped
        case detailRoadMapTapped
        case exitTapped
    }
    
    let actionPublisher = PassthroughSubject<Action, Never>()
    
    private let titleView: UIView = UIView()
    private let iconImageView: UIImageView = UIImageView()
    private let trainInfoLabel: UILabel = UILabel()
    private let remainStationLabel: UILabel = UILabel()
    private let reloadImageView: UIImageView = UIImageView()
    
    private let timeView: UIView = UIView()
    private let minuteLabel: UILabel = UILabel()
    private let minuteTimeLabel: UILabel = UILabel()
    private let secondLabel: UILabel = UILabel()
    private let secondTimeLabel: UILabel = UILabel()
    
    
    private let trainIconImageView: UIImageView = UIImageView()
    private let trainTimeLabel: UILabel = UILabel()
    private let trainRigtImageView: UIImageView = UIImageView()
    private let trainRemainStationLabel: UILabel = UILabel()
    private let alreadySoonLabel: UILabel = UILabel()
    private lazy var trainStackView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [trainIconImageView, trainTimeLabel, trainRemainStationLabel, trainRigtImageView, reloadImageView])
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        return stackView
    }()
    
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
        
        // MARK: Test
        iconImageView.image = UIImage.route16PxBus
        iconImageView.tintColor = .green
        trainInfoLabel.attributedText = AtchaFont.B4_R_15("강남역", color: .white)
        remainStationLabel.attributedText = AtchaFont.B4_R_15("6정류장 전", color: .white)
        
        minuteLabel.attributedText = AtchaFont.B1_R_17("분", color: .widearea)
        secondLabel.attributedText = AtchaFont.B1_R_17("초", color: .widearea)
        minuteTimeLabel.attributedText = AtchaFont.D2_EB_48("\(07)", color: .widearea)
        secondTimeLabel.attributedText = AtchaFont.D2_EB_48("\(05)", color: .widearea)
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
        locationLabel.isUserInteractionEnabled = true
        locationLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleLocationTapped)))
    }
}

// MARK: Binding Leg Info
extension LastTrainRealTimeBottomView {
    func setupLegInfo(info: LegInfo) {
        
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
    
    @objc private func handleLocationTapped() {
        actionPublisher.send(.locationTapped)
    }
}
