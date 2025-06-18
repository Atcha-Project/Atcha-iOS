//
//  BackOnlyNavigationBar.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/18/25.
//

import Foundation
import UIKit
import SnapKit

// MARK: - BackOnly NavigationBar
final class BackOnlyNavigationBar: UIView {
    
    var onTapBack: (() -> Void)?
    
    private let backButton = UIButton()
    
    init(onTapBack: (() -> Void)? = nil) {
        self.onTapBack = onTapBack
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - BackOnly NavigationBar UI
    private func setupUI(){
        backgroundColor = .clear
        
        backButton.setImage(UIImage.chevronLeft, for: .normal)
        backButton.tintColor = AtchaColor.white
        
        backButton.backgroundColor = AtchaColor.gray950
        backButton.layer.cornerRadius = 36 / 2
        backButton.clipsToBounds = true
        
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        addSubview(backButton)
        
        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(36)
        }
        
        snp.makeConstraints { $0.height.equalTo(60) }
    }
    
    // MARK: - Action Method
    @objc private func didTapBack() {
        onTapBack?()
    }
}
