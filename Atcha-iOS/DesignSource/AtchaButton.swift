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
    case xl, lg, md, sm, xs
    
    var height: CGFloat {
        switch self {
        case .xl: return 52
        case .lg: return 48
        case .md: return 44
        case .sm: return 40
        case .xs: return 32
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .xl, .lg: return 14
        case .md: return 13
        case .sm: return 11
        case .xs: return 7
        }
    }
    
    var horizontalPadding: CGFloat {
        return 28
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .xl, .lg, .md: return 10
        case .sm, .xs: return 8
        }
    }
    
    var contentInsets: UIEdgeInsets {
        return UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
    }
    
    func attributedTitle(_ text: String, color: UIColor = .black) -> NSAttributedString {
        switch self {
        case .xl:
            return AtchaFont.H5_B_17(text, color: color)
        case .lg:
            return AtchaFont.H6_B_15(text, color: color)
        case .md, .sm, .xs:
            return AtchaFont.Body_SB_14(text, color: color)
        }
    }
}


// MARK: - FilledButtonStyle
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


// MARK: - FilledButton
final class FilledButton: BaseButton {
    init(text: String, size: ButtonSize, style: FilledButtonStyle, onTap: (() -> Void)? = nil) {
        super.init(text: text, size: size, onTap: onTap)
        
        setAttributedTitle(size.attributedTitle(text, color: style.textColor), for: .normal)
        backgroundColor = style.backgroundColor
        contentEdgeInsets = size.contentInsets
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - LineButtonStyle
enum LineButtonStyle {
    case line, disabled
    
    var textColor: UIColor {
        switch self {
        case .line: return AtchaColor.white
        case .disabled: return AtchaColor.gray700
        }
    }
}


// MARK: - LineButton
final class LineButton: BaseButton {
    init(text: String, size: ButtonSize, style: LineButtonStyle, onTap: (() -> Void)? = nil) {
        super.init(text: text, size: size, onTap: onTap)
        
        setAttributedTitle(size.attributedTitle(text, color: style.textColor), for: .normal)
        backgroundColor = .clear
        contentEdgeInsets = size.contentInsets
        layer.borderWidth = 1
        layer.borderColor = AtchaColor.gray800.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: - BaseButton
class BaseButton: UIButton {
    private var onTap: (() -> Void)?
    
    init(text: String, size: ButtonSize, onTap: (() -> Void)? = nil) {
        self.onTap = onTap
        super.init(frame: .zero)
        
        layer.cornerRadius = size.cornerRadius
        clipsToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
        translatesAutoresizingMaskIntoConstraints = false
        snp.makeConstraints { $0.height.equalTo(size.height) }
        
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
