//
//  RegisterTextField.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/19/25.
//

import Foundation
import UIKit
import SnapKit

// MARK: - 집주소 등록 시 검색 TextField
final class RegisterTextField: UIView {
    var onTextChange: ((String) -> Void)?
    var onTextReset: (() -> Void)?
    var onTextSubmit: ((String) -> Void)?
    
    private let textField = UITextField()
    private let resetButton = UIButton()
    
    init(onTextChange: ((String) -> Void)? = nil) {
        self.onTextChange = onTextChange
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 집주소 등록 시 검색 TextField UI
    private func setupUI() {
        textField.attributedPlaceholder = AtchaFont.Body_M_15("지번, 도로명, 건물명으로 검색", color: AtchaColor.gray400)
        textField.textColor = AtchaColor.white
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        textField.returnKeyType = .done // ✅ 완료 버튼 설정
        textField.delegate = self
        
        resetButton.setImage(UIImage.xCircleGray200, for: .normal)
        resetButton.tintColor = AtchaColor.gray200
        resetButton.isHidden = true
        resetButton.addTarget(self, action: #selector(didTapReset), for: .touchUpInside)
        
        let textfieldStack = UIStackView(arrangedSubviews: [textField, resetButton])
        textfieldStack.axis = .horizontal
        textfieldStack.spacing = 12
        textfieldStack.alignment = .center
        textfieldStack.backgroundColor = AtchaColor.gray930
        textfieldStack.layer.cornerRadius = 8
        textfieldStack.isLayoutMarginsRelativeArrangement = true
        textfieldStack.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        
        
        addSubview(textfieldStack)
        
        textfieldStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        resetButton.snp.makeConstraints {
            $0.size.equalTo(16)
        }
        
        snp.makeConstraints { $0.height.equalTo(40) }
    }
    
    // MARK: - Action Method
    @objc private func textFieldDidChange(_ sender: UITextField) {
        let address = sender.text ?? ""
        
        resetButton.isHidden = address.isEmpty
        onTextChange?(address)
    }
    
    @objc private func didTapReset() {
        textField.text = ""
        resetButton.isHidden = true
        onTextReset?()
        onTextChange?("")
    }
}

extension RegisterTextField: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  // 키보드 내림
        onTextSubmit?(textField.text ?? "")
        return true
    }
}
