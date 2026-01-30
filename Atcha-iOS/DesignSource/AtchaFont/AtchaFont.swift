//
//  AtchaFont.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/15/25.
//

import UIKit

enum AtchaFont {
    // MARK: - Pretendard Weights
    enum Pretendard: String {
        case Bold = "Pretendard-Bold"
        case ExtraBold = "Pretendard-ExtraBold"
        case Medium = "Pretendard-Medium"
        case Regular = "Pretendard-Regular"
        case SemiBold = "Pretendard-SemiBold"
    }
    
    // MARK: - 공통 생성기
    private static func styled(_ fontName: Pretendard,
                               size: CGFloat,
                               lineHeight: CGFloat,
                               text: String,
                               color: UIColor = .label,
                               letterSpacing: CGFloat = 0,
                               alignment: NSTextAlignment = .left) -> NSAttributedString {
        let font = UIFont(name: fontName.rawValue, size: size)!
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .kern: letterSpacing,
            .paragraphStyle: paragraph
        ]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    // MARK: - Display Styles
    // Display 1
    static func D1_EB_56(lineHeight: CGFloat = 67, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.ExtraBold, size: 56, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Display 2
    static func D2_EB_48(lineHeight: CGFloat = 54, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.ExtraBold, size: 48, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Display 3
    static func D3_EB_40(lineHeight: CGFloat = 42, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.ExtraBold, size: 40, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Display 4
    static func D4_B_28(lineHeight: CGFloat = 34, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Bold, size: 44, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // MARK: - Heading Styles
    // Heading 1
    static func H1_B_26(lineHeight: CGFloat = 34, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Bold, size: 26, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Heading 2
    static func H2_B_22(lineHeight: CGFloat = 28, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Bold, size: 22, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Heading 3
    static func H3_B_20(lineHeight: CGFloat = 25, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Bold, size: 20, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Heading 4
    static func H4_SB_17(lineHeight: CGFloat = 24, _ text: String?, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.SemiBold, size: 17, lineHeight: lineHeight, text: text ?? "", color: color, alignment: alignment)
    }
    
    
    // MARK: - Body Styles
    // Body 1
    static func B1_R_17(lineHeight: CGFloat = 24, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Regular, size: 17, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Body 2
    static func B2_SB_15(lineHeight: CGFloat = 20, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.SemiBold, size: 15, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Body 3
    static func B3_M_15(lineHeight: CGFloat = 20, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Medium, size: 15, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Body 4
    static func B4_R_15(lineHeight: CGFloat = 20, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Regular, size: 15, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Body 5
    static func B5_SB_14(lineHeight: CGFloat = 18, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.SemiBold, size: 14, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Body 6
    static func B6_R_14(lineHeight: CGFloat = 18, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Regular, size: 14, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Body 7
    static func B7_M_13(lineHeight: CGFloat = 16, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Medium, size: 13, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // MARK: - Detail Styles
    // Detail 1
    static func R_12(lineHeight: CGFloat = 14, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Regular, size: 12, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Detail 2
    static func M_11(lineHeight: CGFloat = 13, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Medium, size: 11, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // Detail 3
    static func M_9(lineHeight: CGFloat = 11, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Medium, size: 9, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // B8_R_13
    static func R_13(lineHeight: CGFloat = 15, _ text: String, color: UIColor = .label, alignment: NSTextAlignment = .left) -> NSAttributedString {
        styled(.Regular, size: 13, lineHeight: lineHeight, text: text, color: color, alignment: alignment)
    }
    
    // MARK: - 사용 예시
    //
    // UILabel:
    // titleLabel.attributedText = AtchaFont.H2_SB_26("자리에서 떠나기 전에")
    // descriptionLabel.attributedText = AtchaFont.Body_R_12("설명 텍스트입니다", color: AtchaColor.gray600)
    //
    // UIButton:
    // actionButton.setAttributedTitle(AtchaFont.Body_SB_14("확인", color: .white), for: .normal)
    //
    // UITextView:
    // textView.attributedText = AtchaFont.Body_M_15("공지사항 본문 내용")
}
