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
    private static func styled(_ fontName: Pretendard, size: CGFloat, lineHeight: CGFloat, text: String, color: UIColor = .label, letterSpacing: CGFloat = 0) -> NSAttributedString {
        let font = UIFont(name: fontName.rawValue, size: size)!
        let paragraph = NSMutableParagraphStyle()
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
    
    // MARK: - Heading Styles
    static func H1_EB_56(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.ExtraBold, size: 56, lineHeight: 72, text: text, color: color)
    }
    
    static func H1_SB_34(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 34, lineHeight: 41, text: text, color: color)
    }
    
    static func H1_B_34(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Bold, size: 34, lineHeight: 41, text: text, color: color)
    }
    
    static func H2_SB_26(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 26, lineHeight: 34, text: text, color: color)
    }
    
    static func H2_B_26(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Bold, size: 26, lineHeight: 34, text: text, color: color)
    }
    
    static func H3_SB_22(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 22, lineHeight: 28, text: text, color: color)
    }
    
    static func H3_B_22(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Bold, size: 22, lineHeight: 28, text: text, color: color)
    }
    
    static func H4_SB_20(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 20, lineHeight: 25, text: text, color: color)
    }
    
    static func H4_B_20(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Bold, size: 20, lineHeight: 25, text: text, color: color)
    }
    
    static func H4_M_20(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 20, lineHeight: 25, text: text, color: color)
    }
    
    static func H5_SB_17(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 17, lineHeight: 24, text: text, color: color)
    }
    
    static func H5_B_17(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Bold, size: 17, lineHeight: 24, text: text, color: color)
    }
    
    static func H6_SB_15(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 15, lineHeight: 20, text: text, color: color)
    }
    
    static func H6_B_15(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Bold, size: 15, lineHeight: 20, text: text, color: color)
    }
    
    // MARK: - Body Styles
    static func Body_M_17(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 17, lineHeight: 24, text: text, color: color)
    }
    
    static func Body_R_17(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Regular, size: 17, lineHeight: 24, text: text, color: color)
    }
    
    static func Body_M_15(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 15, lineHeight: 20, text: text, color: color)
    }
    
    static func Body_R_15(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Regular, size: 15, lineHeight: 20, text: text, color: color)
    }
    
    static func Body_SB_14(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 14, lineHeight: 18, text: text, color: color)
    }
    
    static func Body_M_14(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 14, lineHeight: 18, text: text, color: color)
    }
    
    static func Body_R_14(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Regular, size: 14, lineHeight: 18, text: text, color: color)
    }
    
    static func Body_SB_13(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 13, lineHeight: 16, text: text, color: color)
    }
    
    static func Body_M_13(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 13, lineHeight: 16, text: text, color: color)
    }
    
    static func Body_R_13(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Regular, size: 13, lineHeight: 16, text: text, color: color)
    }
    
    static func Body_SB_12(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 12, lineHeight: 14, text: text, color: color)
    }
    
    static func Body_M_12(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 12, lineHeight: 14, text: text, color: color)
    }
    
    static func Body_R_12(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Regular, size: 12, lineHeight: 14, text: text, color: color)
    }
    
    static func Body_SB_11(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 11, lineHeight: 13, text: text, color: color)
    }
    
    static func Body_M_11(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 11, lineHeight: 13, text: text, color: color)
    }
    
    static func Body_R_11(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Regular, size: 11, lineHeight: 13, text: text, color: color)
    }
    
    static func Body_SB_10(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.SemiBold, size: 10, lineHeight: 12, text: text, color: color)
    }
    
    static func Body_M_10(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Medium, size: 10, lineHeight: 12, text: text, color: color)
    }
    
    static func Body_R_10(_ text: String, color: UIColor = .label) -> NSAttributedString {
        styled(.Regular, size: 10, lineHeight: 12, text: text, color: color)
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
