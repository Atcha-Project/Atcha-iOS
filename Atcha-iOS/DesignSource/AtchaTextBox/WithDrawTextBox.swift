//
//  WithDrawTextBox.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/27/25.
//

import UIKit
import SnapKit

final class WithDrawTextBox: UIView {
    
    var onTextChange: ((String) -> Void)?
    var text: String? { textView.text }
    
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    
    init(onTextChange: ((String) -> Void)? = nil) {
        self.onTextChange = onTextChange
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = AtchaColor.gray940
        layer.cornerRadius = 12
        addSubViews(textView, placeholderLabel)
        
        // TextView 기본 세팅
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.isScrollEnabled = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.addDoneButtonOnKeyboard(title: "완료") 
        
        placeholderLabel.attributedText = AtchaFont.B6_R_14(
            "탈퇴 이유에 대해 자세히 알려주시면 서비스 개선에 큰 도움이 돼요.",
            color: AtchaColor.gray400
        )
        placeholderLabel.numberOfLines = 0
        
        placeholderLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
        }
        
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        self.snp.makeConstraints { $0.height.equalTo(110) }
    }
    
    func setText(_ text: String) {
        textView.text = text
        placeholderLabel.isHidden = !text.isEmpty
        onTextChange?(text)
    }
}

extension WithDrawTextBox: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        onTextChange?(textView.text)
        textView.attributedText = AtchaFont.B6_R_14(
            "\(textView.text ?? "")",
            color: AtchaColor.white
        )
    }
}
