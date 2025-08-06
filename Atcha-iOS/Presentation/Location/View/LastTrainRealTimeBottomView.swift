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
    
    private let reloadImageView: UIImageView = UIImageView()
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
    }
    
    private func setupAutoLayout() {
        
    }
    
    private func setupActions() {
        
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
