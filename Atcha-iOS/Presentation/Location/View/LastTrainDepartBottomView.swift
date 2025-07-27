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
    private let departTimeLabel: UILabel = UILabel()
    private let departIconImageView: UIImageView = UIImageView()
    private let reloadImageView: UIImageView = UIImageView()
    
    private let timeView: UIView = UIView()
    private let hourTimeLabel: UILabel = UILabel()
    private let hourLabel: UILabel = UILabel()
    private let miniuteLabel: UILabel = UILabel()
    private let minuteTimeLabel: UILabel = UILabel()

    private let locationLabel: UILabel = UILabel()
    
    private lazy var buttonStackView: UIStackView = {
        let stackView: UIStackView = UIStackView(arrangedSubviews: [exitButton, detailRoadMapButton])
        stackView.spacing = 12
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.alignment = .center
        return stackView
    }()
    private let exitButton: AtchaButton = AtchaButton(text: "종료",
                                                      size: .h48,
                                                      style: .line(.line))
    private let detailRoadMapButton: AtchaButton = AtchaButton(text: "상세 경로",
                                                               size: .h48,
                                                               style: .filled(.opacity),
                                                               image: UIImage.home16Px)
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupAutoLayout()
    }
    
    private func setupUI() {
        backgroundColor = .gray950
        layer.cornerRadius = 20
        titleView.addSubViews(departTimeLabel, departIconImageView, reloadImageView)
        timeView.addSubViews(hourLabel, hourTimeLabel, miniuteLabel, minuteTimeLabel)
        addSubViews(titleView, timeView, locationLabel, buttonStackView)
        
        departTimeLabel.attributedText = AtchaFont.B4_R_15("출발시간", color: .white)
        
        departIconImageView.image = UIImage.infoOutlined
        departIconImageView.contentMode = .scaleAspectFit
        departIconImageView.tintColor = .gray500
        
        reloadImageView.image = UIImage.refreshOutlined
        reloadImageView.contentMode = .scaleAspectFit
        reloadImageView.tintColor = .white
        
        hourLabel.attributedText = AtchaFont.B1_R_17("시", color: .white)
        miniuteLabel.attributedText = AtchaFont.B1_R_17("분", color: .white)
        
        exitButton.setContentHuggingPriority(.required, for: .horizontal)
        exitButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        detailRoadMapButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailRoadMapButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        hourTimeLabel.attributedText = AtchaFont.D2_EB_44("22", color: .white)
        minuteTimeLabel.attributedText = AtchaFont.D2_EB_44("28", color: .white)
        locationLabel.attributedText = AtchaFont.B4_R_15("앗차 강남점 -> 우리집", color: .gray300)
    }
    
    private func setupAutoLayout() {
        titleView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(24)
            make.height.equalTo(28)
        }
        
        departTimeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        departIconImageView.snp.makeConstraints { make in
            make.leading.equalTo(departTimeLabel.snp.trailing).offset(6)
            make.centerY.equalTo(departTimeLabel.snp.centerY)
            make.width.height.equalTo(14)
        }
        
        reloadImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        timeView.snp.makeConstraints { make in
            make.height.equalTo(66)
            make.top.equalTo(titleView.snp.bottom)
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
    
    func setupTime(hour: String, minute: String) {
        hourTimeLabel.attributedText = AtchaFont.D2_EB_44(hour, color: .white)
        minuteTimeLabel.attributedText = AtchaFont.D2_EB_44(minute, color: .white)
    }
    
    func setupLoaction(location: String) {
        locationLabel.attributedText = AtchaFont.B4_R_15(location, color: .gray300)
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
