//
//  AtchaButton.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/17/25.
//

import Foundation
import UIKit
import SnapKit

// MARK: - 버튼 사이즈 Enum
enum ButtonSize {
    case h52, h48, h44, h32
    
    var height: CGFloat {
        switch self {
        case .h52: return 52
        case .h48: return 48
        case .h44: return 44
        case .h32: return 32
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .h52, .h48: return 14
        case .h44: return 13
        case .h32: return 7
        }
    }
    
    var horizontalPadding: CGFloat { 28 }
    
    var cornerRadius: CGFloat {
        switch self {
        case .h52, .h48, .h44: return 10
        case .h32: return 8
        }
    }
    
    var contentInsets: UIEdgeInsets {
        UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
    }
}

// MARK: - FilledButtonStyle: 테두리 없는 버튼
enum FilledButtonStyle {
    case primary, white, defaultGray, opacity, disabled
    
    var backgroundColor: UIColor {
        switch self {
        case .primary: return AtchaColor.main
        case .white: return AtchaColor.white
        case .defaultGray: return AtchaColor.gray910
        case .opacity: return AtchaColor.main.withAlphaComponent(0.12)
        case .disabled: return AtchaColor.opacity200
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .primary, .white: return AtchaColor.black
        case .defaultGray: return AtchaColor.white
        case .opacity: return AtchaColor.main
        case .disabled: return AtchaColor.gray700
        }
    }
}

// MARK: - LineButtonStyle: 테두리 있는 버튼
enum LineButtonStyle {
    case line, disabled
    
    var textColor: UIColor {
        switch self {
        case .line: return AtchaColor.white
        case .disabled: return AtchaColor.gray700
        }
    }
    
    var borderColor: UIColor {
        return AtchaColor.gray800
    }
}

// MARK: - AtchaButton
final class AtchaButton: UIButton {
    enum Style {
        case filled(FilledButtonStyle)
        case line(LineButtonStyle)
    }
    
    private var onTap: (() -> Void)?
    private let size: ButtonSize
    
    init(
        text: String,
        size: ButtonSize,
        style: Style,
        image: UIImage? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.onTap = onTap
        self.size = size
        super.init(frame: .zero)
        
        layer.cornerRadius = size.cornerRadius
        clipsToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
        translatesAutoresizingMaskIntoConstraints = false
        snp.makeConstraints { $0.height.equalTo(size.height).priority(.high) }
        contentEdgeInsets = size.contentInsets
        
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        
        switch style {
        case .filled(let filledStyle):
            setAttributedTitle(filledStyle.attributedText(text, size: size), for: .normal)
            backgroundColor = filledStyle.backgroundColor
            
        case .line(let lineStyle):
            setAttributedTitle(lineStyle.attributedText(text, size: size), for: .normal)
            backgroundColor = .clear
            layer.borderWidth = 1
            layer.borderColor = lineStyle.borderColor.cgColor
        }
        
        if let image = image {
            setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
            tintColor = {
                switch style {
                case .filled(let filledStyle):
                    return filledStyle.textColor
                case .line(let lineStyle):
                    return lineStyle.textColor
                }
            }()
            
            imageView?.contentMode = .scaleAspectFit
            
            let spacing: CGFloat = 6
            semanticContentAttribute = .forceLeftToRight
            imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing/2, bottom: 0, right: spacing/2)
            titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing/2, bottom: 0, right: -spacing/2)
        }
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension FilledButtonStyle {
    func attributedText(_ text: String, size: ButtonSize) -> NSAttributedString {
        switch (self, size) {
        case (.primary, .h52): return AtchaFont.H4_SB_17(lineHeight: 0, text, color: textColor)
        case (.primary, .h48): return AtchaFont.B2_SB_15(lineHeight: 0, text, color: textColor)
        case (.primary, .h44): return AtchaFont.B5_SB_14(lineHeight: 0, text, color: textColor)
        case (.primary, .h32): return AtchaFont.B5_SB_14(lineHeight: 0, text, color: textColor)

        case (.white, .h52): return AtchaFont.H4_SB_17(lineHeight: 0, text, color: textColor)
        case (.white, .h48): return AtchaFont.B2_SB_15(lineHeight: 0, text, color: textColor)
        case (.white, .h44): return AtchaFont.B5_SB_14(lineHeight: 0, text, color: textColor)
        case (.white, .h32): return AtchaFont.B5_SB_14(lineHeight: 0, text, color: textColor)

        case (.defaultGray, .h52): return AtchaFont.B1_R_17(lineHeight: 0, text, color: textColor)
        case (.defaultGray, .h48): return AtchaFont.B3_M_15(lineHeight: 0,text, color: textColor)
        case (.defaultGray, .h44): return AtchaFont.B6_R_14(lineHeight: 0, text, color: textColor)
        case (.defaultGray, .h32): return AtchaFont.B6_R_14(lineHeight: 0, text, color: textColor)
            
        case (.opacity, .h52): return AtchaFont.B1_R_17(lineHeight: 0, text, color: textColor)
        case (.opacity, .h48): return AtchaFont.B3_M_15(lineHeight: 0, text, color: textColor)
        case (.opacity, .h44): return AtchaFont.B6_R_14(lineHeight: 0, text, color: textColor)
        case (.opacity, .h32): return AtchaFont.B6_R_14(lineHeight: 0, text, color: textColor)
            
        case (.disabled, .h52): return AtchaFont.B1_R_17(lineHeight: 0, text, color: textColor)
        case (.disabled, .h48): return AtchaFont.B3_M_15(lineHeight: 0, text, color: textColor)
        case (.disabled, .h44): return AtchaFont.B6_R_14(lineHeight: 0, text, color: textColor)
        case (.disabled, .h32): return AtchaFont.B6_R_14(lineHeight: 0, text, color: textColor)
        }
    }
}

extension LineButtonStyle {
    func attributedText(_ text: String, size: ButtonSize) -> NSAttributedString {
        switch (self, size) {
        case (.line, .h52): return AtchaFont.B1_R_17(lineHeight: 0, text, color: textColor)
        case (.line, .h48): return AtchaFont.B4_R_15(lineHeight: 0, text, color: textColor)
        case (.line, .h44): return AtchaFont.B6_R_14(lineHeight: 0, text, color: textColor)
        case (.line, .h32): return AtchaFont.B6_R_14(lineHeight: 0, text, color: textColor)
            
        case (.disabled, .h52): return AtchaFont.B1_R_17(lineHeight: 0, text, color: textColor)
        case (.disabled, .h48): return AtchaFont.B4_R_15(lineHeight: 0, text, color: textColor)
        case (.disabled, .h44): return AtchaFont.B6_R_14(lineHeight: 0, text, color: textColor)
        case (.disabled, .h32): return AtchaFont.B6_R_14(lineHeight: 0, text, color: textColor)
        }
    }
}

extension AtchaButton {
    func updateStyle(text: String, style: Style) {
        switch style {
        case .filled(let filledStyle):
            setAttributedTitle(filledStyle.attributedText(text, size: size), for: .normal)
            backgroundColor = filledStyle.backgroundColor
            layer.borderWidth = 0
            layer.borderColor = nil
            
        case .line(let lineStyle):
            setAttributedTitle(lineStyle.attributedText(text, size: size), for: .normal)
            backgroundColor = .clear
            layer.borderWidth = 1
            layer.borderColor = lineStyle.borderColor.cgColor
        }
    }
}

extension AtchaButton {
    /// 버튼의 텍스트와 스타일을 업데이트
    func updateStyle(
        text: String? = nil,
        style: Style
    ) {
        // 텍스트 업데이트 (없으면 기존 타이틀 유지)
        let currentText = text ?? (title(for: .normal) ?? "")
        
        switch style {
        case .filled(let filledStyle):
            setAttributedTitle(filledStyle.attributedText(currentText, size: size), for: .normal)
            backgroundColor = filledStyle.backgroundColor
            setTitleColor(filledStyle.textColor, for: .normal)
            layer.borderWidth = 0
            layer.borderColor = nil
            
        case .line(let lineStyle):
            setAttributedTitle(lineStyle.attributedText(currentText, size: size), for: .normal)
            backgroundColor = .clear
            setTitleColor(lineStyle.textColor, for: .normal)
            layer.borderWidth = 1
            layer.borderColor = lineStyle.borderColor.cgColor
        }
        
        // 아이콘 있는 경우 색상 맞춰주기
        if let imageView = imageView, imageView.image != nil {
            switch style {
            case .filled(let filledStyle):
                tintColor = filledStyle.textColor
            case .line(let lineStyle):
                tintColor = lineStyle.textColor
            }
        }
    }
}

// MARK: - 사용예시
//
//let button1 = AtchaButton(
//    text: "확인",
//    size: .md,
//    style: .filled(.primary)
//) {
//    print("✅ Filled primary tapped")
//}
//
//let button2 = AtchaButton(
//    text: "취소",
//    size: .sm,
//    style: .line(.disabled)
//) {
//    print("⚪️ Line disabled tapped")
//}

