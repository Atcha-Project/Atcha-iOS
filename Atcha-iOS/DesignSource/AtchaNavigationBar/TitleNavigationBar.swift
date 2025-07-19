//
//  TitleNavigationBar.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/18/25.
//

import Foundation
import UIKit
import SnapKit

// MARK: - Title만 존재하는 NavigationBar
final class TitleNavigationBar: UIView {
    
    var onTapBack: (() -> Void)?
    var onTapClose: (() -> Void)?
    
    private let backButton = UIButton()
    private let titleLabel = UILabel()
    private let closeButton = UIButton()
    private let shouldShowCloseButton: Bool
    
    init(title: String? = nil,
         shouldShowCloseButton: Bool = true,
         onTapBack: (() -> Void)? = nil,
         onTapClose: (() -> Void)? = nil) {
        self.onTapBack = onTapBack
        self.onTapClose = onTapClose
        self.shouldShowCloseButton = shouldShowCloseButton
        super.init(frame: .zero)
        
        setupUI(title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Title NavigationBar UI
    private func setupUI(title: String?) {
        backgroundColor = AtchaColor.gray950
        
        backButton.setImage(UIImage.chevronLeft, for: .normal)
        backButton.tintColor = AtchaColor.gray300
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)

        closeButton.setImage(UIImage.x, for: .normal)
        closeButton.tintColor = AtchaColor.gray300
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        closeButton.isHidden = !shouldShowCloseButton
        
        titleLabel.attributedText = AtchaFont.H4_SB_17(title)
        titleLabel.textColor = AtchaColor.white
        titleLabel.textAlignment = .center

        addSubview(backButton)
        addSubview(titleLabel)
        addSubview(closeButton)

        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        closeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        snp.makeConstraints { $0.height.equalTo(60) }
    }

    // MARK: - Action Method
    @objc private func didTapBack() {
        onTapBack?()
    }

    @objc private func didTapClose() {
        onTapClose?()
    }
    
    // MARK: - CloseButton 숨김
    func hideCloseButton() {
        closeButton.isHidden = true
    }
}
