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

    func attributedTitle(_ text: String, color: UIColor = .black) -> NSAttributedString {
        switch self {
        case .h52:
            return AtchaFont.H4_SB_17(text, color: color)
        case .h48:
            return AtchaFont.B2_SB_15(text, color: color)
        case .h44, .h32:
            return AtchaFont.B5_SB_14(text, color: color)
        }
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

    init(text: String, size: ButtonSize, style: Style, onTap: (() -> Void)? = nil) {
        self.onTap = onTap
        super.init(frame: .zero)

        layer.cornerRadius = size.cornerRadius
        clipsToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
        translatesAutoresizingMaskIntoConstraints = false
        snp.makeConstraints { $0.height.equalTo(size.height) }

        contentEdgeInsets = size.contentInsets
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        switch style {
        case .filled(let filledStyle):
            setAttributedTitle(size.attributedTitle(text, color: filledStyle.textColor), for: .normal)
            backgroundColor = filledStyle.backgroundColor

        case .line(let lineStyle):
            setAttributedTitle(size.attributedTitle(text, color: lineStyle.textColor), for: .normal)
            backgroundColor = .clear
            layer.borderWidth = 1
            layer.borderColor = lineStyle.borderColor.cgColor
        }
    }

    @objc private func handleTap() {
        onTap?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AtchaButton {
    func updateStyle(text: String, style: Style) {
        switch style {
        case .filled(let filledStyle):
            setAttributedTitle(ButtonSize.h52.attributedTitle(text, color: filledStyle.textColor), for: .normal)
            backgroundColor = filledStyle.backgroundColor
            layer.borderWidth = 0
            layer.borderColor = nil

        case .line(let lineStyle):
            setAttributedTitle(ButtonSize.h52.attributedTitle(text, color: lineStyle.textColor), for: .normal)
            backgroundColor = .clear
            layer.borderWidth = 1
            layer.borderColor = lineStyle.borderColor.cgColor
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

