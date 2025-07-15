//
//  LastTrainSearchBottomView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/6/25.
//

import UIKit
import Combine

final class LastTrainSearchBottomView: UIView {
    enum Action {
        case currentTapped
        case searchTapped
    }
    
    let actionPublisher = PassthroughSubject<Action, Never>()
    
    private let currentDotView: UIView = UIView()
    private let arrivalDotView: UIView = UIView()
    private let currentLocationLabel: UILabel = UILabel()
    private let arrivalLocationLabel: UILabel = UILabel()
    
    private lazy var currentLocationView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [currentDotView, currentLocationLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.backgroundColor = .gray930
        stack.layer.cornerRadius = 10
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return stack
    }()
    
    private lazy var arrivalLocationView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [arrivalDotView, arrivalLocationLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.backgroundColor = .clear
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return stack
    }()
    
    private let searchButton: AtchaButton = AtchaButton(text: "검색하기",
                                                        size: .h52,
                                                        style: .filled(.primary),
                                                        image: UIImage(named: "search")) {}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupConstraints()
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = .gray950
        layer.cornerRadius = 20
        
        currentLocationView.backgroundColor = .gray930
        currentDotView.backgroundColor = .main
        arrivalDotView.backgroundColor = .gray200
        
        currentDotView.layer.cornerRadius = 2
        arrivalDotView.layer.cornerRadius = 2
        
        currentLocationLabel.attributedText = AtchaFont.B1_R_17("현위치 : 조회 중..", color: .main)
        arrivalLocationLabel.attributedText = AtchaFont.B1_R_17("도착지 : 우리집", color: .gray200)
        
        addSubViews(currentLocationView, arrivalLocationView, searchButton)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleCurrentTap))
        currentLocationView.isUserInteractionEnabled = true
        currentLocationView.addGestureRecognizer(tap)
        
        searchButton.addTarget(self, action: #selector(handleSearchTap), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        currentLocationView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }
        
        currentDotView.snp.makeConstraints { make in
            make.width.height.equalTo(4)
        }
        
        arrivalDotView.snp.makeConstraints { make in
            make.width.height.equalTo(4)
        }
        
        arrivalLocationView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.top.equalTo(currentLocationView.snp.bottom).inset(-8)
            make.height.equalTo(48)
        }
        
        searchButton.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(18)
            make.top.equalTo(arrivalLocationView.snp.bottom).inset(-24)
        }
    }
    
    func setupCurrentLocationTitle(_ address: String) {
        // TODO: - 현재 내 위치랑 동일한 경우, 현위치 포함 아닌경우 pass
        currentLocationLabel.attributedText = AtchaFont.B1_R_17("현위치 : \(address)", color: .main)
    }
}

extension LastTrainSearchBottomView {
    @objc private func handleCurrentTap() {
        actionPublisher.send(.currentTapped)
    }

    @objc private func handleSearchTap() {
        actionPublisher.send(.searchTapped)
    }
}
