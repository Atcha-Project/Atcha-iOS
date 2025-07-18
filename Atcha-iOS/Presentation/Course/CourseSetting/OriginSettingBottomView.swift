//
//  OriginSettingBottomView.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/18/25.
//

import UIKit
import Combine

final class OriginSettingBottomView: UIView {
    enum Action {
        case settingTapped
    }
    
    let actionPublisher = PassthroughSubject<Action, Never>()
    
    private let locationNameLabel: UILabel = UILabel()
    private let locationAdressLabel: UILabel = UILabel()
    private let settingButton: AtchaButton = AtchaButton(text: "출발지로 설정", size: .h48, style: .filled(.primary))
    
    private lazy var locationLabelView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [locationNameLabel, locationAdressLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupAutoLayout()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Setting
    private func setupView() {
        backgroundColor = AtchaColor.gray950
        layer.cornerRadius = 20
        
        locationNameLabel.attributedText = AtchaFont.H4_SB_17("조회 중..", color: AtchaColor.white)
        locationAdressLabel.attributedText = AtchaFont.B6_R_14("조회 중..", color: AtchaColor.gray400)
        
        addSubViews(locationLabelView, settingButton)
        
        settingButton.addTarget(self, action: #selector(handleSettingTap), for: .touchUpInside)
        
    }
    
    private func setupAutoLayout() {
        locationLabelView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(32)
            make.leading.equalToSuperview().offset(16)
        }
        
        settingButton.snp.makeConstraints { make in
            make.top.equalTo(locationLabelView.snp.bottom).inset(-24)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    func setupLocationTitle(_ name: String?, _ address: String?) {
        if let name, !name.isEmpty {
            /// name이 있을 때: name + address 모두 표시
            locationNameLabel.attributedText = AtchaFont.H4_SB_17(name, color: AtchaColor.white)
            locationAdressLabel.attributedText = AtchaFont.B6_R_14(address ?? "", color: AtchaColor.gray400)
            locationAdressLabel.isHidden = false
        } else {
            /// name이 없을 때: address만 nameLabel에 표시, addressLabel은 숨김
            locationNameLabel.attributedText = AtchaFont.H4_SB_17(address ?? "", color: AtchaColor.white)
            locationAdressLabel.isHidden = true
        }
    }
}

extension OriginSettingBottomView {
    @objc private func handleSettingTap() {
        actionPublisher.send(.settingTapped)
    }
}
