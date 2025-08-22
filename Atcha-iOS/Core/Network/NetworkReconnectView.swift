//
//  NetworkReConnectView.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/22/25.
//

import Foundation
import UIKit

final class NetworkReconnectView: UIView {
    
    private let popUpView: UIView = UIView()
    private let titleLabel: UILabel = UILabel()
    private let retryButton: AtchaButton = AtchaButton(text: "재시도", size: .h44, style: .filled(.white))
    
    var onRetry: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = AtchaColor.black.withAlphaComponent(0.76)
        
        titleLabel.attributedText = AtchaFont.H4_SB_17("오프라인 상태입니다.\n네트워크 연결 상태 확인 후,\n다시 시도해주세요.",
                                                       color: AtchaColor.white,
                                                       alignment: .center)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        popUpView.backgroundColor = AtchaColor.gray940
        popUpView.layer.cornerRadius = 20
        
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        
        popUpView.addSubViews(titleLabel, retryButton)
        addSubViews(popUpView)
    }
    
    private func setupAutoLayout() {
        popUpView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(196)
            make.width.equalTo(300)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.centerX.equalToSuperview()
        }
        
        retryButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(28)
        }
    }
    
    @objc private func retryTapped() {
        onRetry?()
    }
}
