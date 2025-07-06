//
//  LastTrainSearchBottomView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/6/25.
//

import UIKit

final class LastTrainSearchBottomView: UIView {
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
                                                        image: UIImage(named: "search")) {
        print("검색 레스고")
    }
    
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
        
        currentLocationLabel.attributedText = AtchaFont.B1_R_17("현위치 : 마루 180", color: .main)
        arrivalLocationLabel.attributedText = AtchaFont.B1_R_17("도착지 : 우리집", color: .gray200)
        
        addSubViews(currentLocationView, arrivalLocationView, searchButton)
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
}
