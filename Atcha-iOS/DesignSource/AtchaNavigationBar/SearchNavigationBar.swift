//
//  SearchNavigationBar.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/18/25.
//

import Foundation
import UIKit
import SnapKit

// MARK: - Search NavigationBar
final class SearchNavigationBar: UIView {
    
    var onTapBack: (() -> Void)?
    var onTapClose: (() -> Void)?
    var onTextChange: ((String) -> Void)?
    
    private let backButton = UIButton()
    private let closeButton = UIButton()
    private let textField = UITextField()
    
    init(onTapBack: (() -> Void)? = nil,
         onTapClose: (() -> Void)? = nil) {
        self.onTapBack = onTapBack
        self.onTapClose = onTapClose
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Search NavigationBar UI
    private func setupUI(){
        backgroundColor = AtchaColor.gray950
        
        backButton.setImage(UIImage.chevronLeft, for: .normal)
        backButton.tintColor = AtchaColor.gray300
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        
        closeButton.setImage(UIImage.x, for: .normal)
        closeButton.tintColor = AtchaColor.gray300
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        
        textField.borderStyle = .roundedRect
        textField.layer.cornerRadius = 8
        textField.layer.masksToBounds = true
        textField.attributedPlaceholder = AtchaFont.Body_M_15("지번, 도로명, 건물명으로 검색", color: AtchaColor.gray400)
        textField.backgroundColor = AtchaColor.gray930
        textField.textColor = AtchaColor.white
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        addSubview(backButton)
        addSubview(textField)
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
        
        textField.snp.makeConstraints {
            $0.leading.equalTo(backButton.snp.trailing).offset(12)
            $0.trailing.equalTo(closeButton.snp.leading).offset(-12)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(40)
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
    
    @objc private func textFieldDidChange(_ sender: UITextField) {
        let address = sender.text ?? ""
        onTextChange?(address)
    }
}
