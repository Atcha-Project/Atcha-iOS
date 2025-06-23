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
final class SearchNavigationBar: UIView{
    
    var onTapBack: (() -> Void)?
    var onTapCurrentLocation: (() -> Void)?
    var onTextChange: ((String) -> Void)?
    
    private let backButton = UIButton()
    private let currentLocationButton = UIButton()
    private let textField = AtchaTextField.registerTextField()
    
    init(onTapBack: (() -> Void)? = nil,
         onTapCurrentLocation: (() -> Void)? = nil) {
        self.onTapBack = onTapBack
        self.onTapCurrentLocation = onTapCurrentLocation
        super.init(frame: .zero)
        
        setupUI()
        setupAction()
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
        
        currentLocationButton.setImage(UIImage.mylocationOutlined, for: .normal)
        currentLocationButton.tintColor = AtchaColor.gray300
        currentLocationButton.addTarget(self, action: #selector(didTapCurrentLocation), for: .touchUpInside)
        
        addSubview(backButton)
        addSubview(textField)
        addSubview(currentLocationButton)
        
        backButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
        
        currentLocationButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }
        
        textField.snp.makeConstraints {
            $0.leading.equalTo(backButton.snp.trailing).offset(12)
            $0.trailing.equalTo(currentLocationButton.snp.leading).offset(-12)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(40)
        }
        
        snp.makeConstraints { $0.height.equalTo(60) }
    }
    
    private func setupAction() {
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        currentLocationButton.addTarget(self, action: #selector(didTapCurrentLocation), for: .touchUpInside)
        
        //RegisterTextField의 콜백 연결
        textField.onTextChange = { [weak self] text in
            self?.onTextChange?(text)
        }
        textField.onTextReset = { [weak self] in
            self?.onTextChange?("")
        }
    }
    
    // MARK: - Action Method
    @objc private func didTapBack() {
        onTapBack?()
    }
    
    @objc private func didTapCurrentLocation() {
        onTapCurrentLocation?()
    }
    
    @objc private func textFieldDidChange(_ sender: UITextField) {
        let address = sender.text ?? ""
        onTextChange?(address)
    }
}
