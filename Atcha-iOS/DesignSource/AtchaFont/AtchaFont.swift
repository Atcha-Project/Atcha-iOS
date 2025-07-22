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
    static func D1_EB_56(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.ExtraBold, size: 56, lineHeight: 67, text: text, color: color)
    }
    
    // Display 2
    static func D2_EB_44(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.ExtraBold, size: 44, lineHeight: 54, text: text, color: color)
    }
    
    // Display 3
    static func D3_EB_40(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.ExtraBold, size: 40, lineHeight: 42, text: text, color: color)
    }
    
    // Display 4
    static func D4_B_28(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Bold, size: 44, lineHeight: 34, text: text, color: color)
    }
    
    // MARK: - Heading Styles
    // Heading 1
    static func H1_B_26(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Bold, size: 26, lineHeight: 34, text: text, color: color)
    }
    
    // Heading 2
    static func H2_B_22(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Bold, size: 22, lineHeight: 28, text: text, color: color)
    }
    
    // Heading 3
    static func H3_B_20(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Bold, size: 20, lineHeight: 25, text: text, color: color)
    }
    
    // Heading 4
    static func H4_SB_17(_ text: String?, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 17, lineHeight: 24, text: text ?? "", color: color)
    }
    
    
    // MARK: - Body Styles
    // Body 1
    static func B1_R_17(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Regular, size: 17, lineHeight: 24, text: text, color: color)
    }
    
    // Body 2
    static func B2_SB_15(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 15, lineHeight: 20, text: text, color: color)
    }
    
    // Body 3
    static func B3_M_15(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 15, lineHeight: 20, text: text, color: color)
    }
    
    // Body 4
    static func B4_R_15(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Regular, size: 15, lineHeight: 20, text: text, color: color)
    }
    
    // Body 5
    static func B5_SB_14(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 14, lineHeight: 18, text: text, color: color)
    }
    
    // Body 6
    static func B6_R_14(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Regular, size: 14, lineHeight: 18, text: text, color: color)
    }
    
    // Body 7
    static func B7_M_13(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 13, lineHeight: 16, text: text, color: color)
    }
    
    // MARK: - Detail Styles
    // Detail 1
    static func R_12(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Regular, size: 12, lineHeight: 14, text: text, color: color)
    }
    
    // Detail 2
    static func M_11(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 11, lineHeight: 13, text: text, color: color)
    }
    
    // Detail 3
    static func M_9(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 9, lineHeight: 11, text: text, color: color)
    }
    
    // MARK: - 사용 예시
    //
    // UILabel:
    // titleLabel.attributedText = AtchaFont.H2_SB_26("자리에서 떠나기 전에", alignment: .center)
    // descriptionLabel.attributedText = AtchaFont.Body_R_12("설명 텍스트입니다", color: AtchaColor.gray600)
    //
    // UIButton:
    // actionButton.setAttributedTitle(AtchaFont.Body_SB_14("확인", color: .white), for: .normal)
    //
    // UITextView:
    // textView.attributedText = AtchaFont.Body_M_15("공지사항 본문 내용")
}
