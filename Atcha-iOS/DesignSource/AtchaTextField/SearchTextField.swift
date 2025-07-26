//
//  SearchTextField.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/19/25.
//

import Foundation
import UIKit
import SnapKit

// MARK: - 주소 검색 TextField
final class SearchTextField: UIView {
    var onTextChange: ((String) -> Void)?
    var onTextReset: (() -> Void)?
    var text: String? {
        return textField.text
    }
    
    private let textField = UITextField()
    private let resetButton = UIButton()
    private let dotView = UIView()
    
    init(onTextChange: ((String) -> Void)? = nil) {
        self.onTextChange = onTextChange
        super.init(frame: .zero)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 주소 검색 TextField UI
    private func setupUI() {
        
        let spacer10 = UIView()
        spacer10.setContentHuggingPriority(.required, for: .horizontal)
        
        let spacer12 = UIView()
        spacer10.setContentHuggingPriority(.required, for: .horizontal)
        
        textField.attributedPlaceholder = AtchaFont.B3_M_15("지번, 도로명, 건물명으로 검색", color: AtchaColor.gray400)
        textField.textColor = AtchaColor.white
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        resetButton.setImage(UIImage.xCircleGray200, for: .normal)
        resetButton.tintColor = AtchaColor.gray200
        resetButton.isHidden = true
        resetButton.addTarget(self, action: #selector(didTapReset), for: .touchUpInside)
        
        dotView.backgroundColor = AtchaColor.main
        dotView.layer.cornerRadius = 2
        
        
        let textfieldStack = UIStackView(arrangedSubviews: [dotView, spacer10, textField, spacer12, resetButton])
        textfieldStack.axis = .horizontal
        textfieldStack.spacing = 0
        textfieldStack.alignment = .center
        textfieldStack.backgroundColor = AtchaColor.gray930
        textfieldStack.layer.cornerRadius = 8
        textfieldStack.isLayoutMarginsRelativeArrangement = true
        textfieldStack.layoutMargins = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        
        
        addSubview(textfieldStack)
        
        textfieldStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        resetButton.snp.makeConstraints {
            $0.size.equalTo(16)
        }
        
        dotView.snp.makeConstraints {
            $0.size.equalTo(4)
        }
        
        spacer10.snp.makeConstraints {
            $0.width.equalTo(10)
        }
        
        spacer12.snp.makeConstraints {
            $0.width.equalTo(12)
        }
        
        snp.makeConstraints { $0.height.equalTo(48) }
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
    
    func setText(_ text: String) {
        textField.text = text
        resetButton.isHidden = text.isEmpty
    }
}
