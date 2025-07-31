//
//  BusDetailHeaderView.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/29/25.
//

import Foundation
import UIKit

final class BusDetailHeaderView: UIView {
    
    var onInfoTap: (() -> Void)?
    private let infoStack = UIStackView()
    private let infoLabel = UILabel()
    private let infoImageView = UIImageView()
    
    private let busRunningStack = UIStackView()
    private let busCountLabel = UILabel()
    private let busRunningLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        infoLabel.attributedText = AtchaFont.B6_R_14(lineHeight: 0, "운행정보", color: AtchaColor.white)
        infoImageView.image = UIImage.infoOutlined
        infoImageView.tintColor = AtchaColor.white
        infoImageView.contentMode = .scaleAspectFit
        infoStack.axis = .horizontal
        infoStack.spacing = 3
        infoStack.addArrangedSubview(infoLabel)
        infoStack.addArrangedSubview(infoImageView)
        
        busCountLabel.attributedText = AtchaFont.B6_R_14(lineHeight: 0, "14", color: AtchaColor.white)
        busRunningLabel.attributedText = AtchaFont.B6_R_14(lineHeight: 0, "대 운행 중", color: AtchaColor.gray200)
        busRunningStack.axis = .horizontal
        busRunningStack.spacing = 2
        busRunningStack.addArrangedSubview(busCountLabel)
        busRunningStack.addArrangedSubview(busRunningLabel)
        
        addSubViews(infoStack, busRunningStack)
    }
    
    private func setupLayout() {
        infoStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        busRunningStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        infoImageView.snp.makeConstraints { make in
            make.size.equalTo(12)
        }
    }
    
    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(infoTapped))
        infoStack.isUserInteractionEnabled = true
        infoLabel.isUserInteractionEnabled = false
        infoImageView.isUserInteractionEnabled = false
        infoStack.addGestureRecognizer(tapGesture)
    }
    
    @objc private func infoTapped() {
        onInfoTap?()
    }
}
