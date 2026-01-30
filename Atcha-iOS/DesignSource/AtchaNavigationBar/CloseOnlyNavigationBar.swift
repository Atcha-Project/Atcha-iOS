//
//  File.swift
//  Atcha-iOS
//
//  Created by wodnd on 1/31/26.
//

import Foundation
import UIKit
import SnapKit

// MARK: - Close만 존재하는 NavigationBar
final class CloseOnlyNavigationBar: UIView {
    
    var onTapClose: (() -> Void)?
    private let closeButton = UIButton()
    
    init(onTapClose: (() -> Void)? = nil) {
        self.onTapClose = onTapClose
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Title NavigationBar UI
    private func setupUI() {
        backgroundColor = AtchaColor.gray950
        

        closeButton.setImage(UIImage.x, for: .normal)
        closeButton.tintColor = AtchaColor.gray300
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        
        addSubview(closeButton)

        closeButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        snp.makeConstraints { $0.height.equalTo(60) }
    }

    // MARK: - Action Method
    @objc private func didTapClose() {
        onTapClose?()
    }
}
