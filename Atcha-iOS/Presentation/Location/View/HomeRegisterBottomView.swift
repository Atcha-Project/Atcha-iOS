//
//  HomeRegisterBottomView.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/8/25.
//

import Foundation
import Combine
import UIKit

final class HomeRegisterBottomView: UIView {
    enum Action {
        case registerTapped
    }
    
    let actionPublisher = PassthroughSubject<Action, Never>()
    
    private let nameLabel: UILabel = UILabel()
    private let addressLabel: UILabel = UILabel()
    private let button: AtchaButton = AtchaButton(text: "우리집 등록",
                                                  size: .h52, style: .filled(.primary))
    
    private lazy var titleStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, addressLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupAutoLayout()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupAutoLayout()
        setupGesture()
    }
    
    func setupNameLabel(name: String?) {
        guard let name else { return }
        nameLabel.attributedText = AtchaFont.H4_SB_17(name, color: .white)
    }
    
    func setupaddressLabel(address: String?) {
        guard let address else { return }
        addressLabel.attributedText = AtchaFont.B4_R_15(address, color: .gray200)
    }
    
    private func setupView() {
        addSubViews(titleStackView, button)
        
        nameLabel.attributedText = AtchaFont.H4_SB_17("", color: .white)
        addressLabel.attributedText = AtchaFont.B4_R_15("", color: .gray200)
        
        backgroundColor = .gray950
        layer.cornerRadius = 20
    }
    
    private func setupGesture() {
        button.addTarget(self,
                         action: #selector(handleRegiTap),
                         for: .touchUpInside)
    }
    
    private func setupAutoLayout() {
        titleStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(32)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        
        button.snp.makeConstraints { make in
            make.top.equalTo(titleStackView.snp.bottom).offset(24)
            make.horizontalEdges.equalTo(titleStackView)
            make.bottom.equalToSuperview().inset(40)
        }
    }
}

extension HomeRegisterBottomView {
    @objc private func handleRegiTap() {
        actionPublisher.send(.registerTapped)
    }
}
