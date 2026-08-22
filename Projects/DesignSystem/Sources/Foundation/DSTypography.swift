import UIKit

// Type scale: font + pinned line height as one token. Single-line labels can
// use `.font` directly; multiline text should go through `attributed(_:)` so
// the line height actually applies.
public struct DSTypography {
    public let font: UIFont
    public let lineHeight: CGFloat

    public func attributed(
        _ text: String,
        color: UIColor,
        alignment: NSTextAlignment = .natural
    ) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        paragraph.alignment = alignment
        return NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph,
            ]
        )
    }

    public static var display: DSTypography { .init(font: DSFont.pretendard(.extraBold, size: 40), lineHeight: 48) }
    public static var title1: DSTypography { .init(font: DSFont.pretendard(.bold, size: 26), lineHeight: 34) }
    public static var title2: DSTypography { .init(font: DSFont.pretendard(.bold, size: 22), lineHeight: 28) }
    public static var title3: DSTypography { .init(font: DSFont.pretendard(.bold, size: 20), lineHeight: 25) }
    public static var heading: DSTypography { .init(font: DSFont.pretendard(.semiBold, size: 17), lineHeight: 24) }
    public static var body1: DSTypography { .init(font: DSFont.pretendard(.regular, size: 17), lineHeight: 24) }
    public static var body2: DSTypography { .init(font: DSFont.pretendard(.regular, size: 15), lineHeight: 22) }
    public static var label1: DSTypography { .init(font: DSFont.pretendard(.semiBold, size: 15), lineHeight: 20) }
    public static var label2: DSTypography { .init(font: DSFont.pretendard(.semiBold, size: 14), lineHeight: 18) }
    public static var caption1: DSTypography { .init(font: DSFont.pretendard(.regular, size: 13), lineHeight: 16) }
    public static var caption2: DSTypography { .init(font: DSFont.pretendard(.medium, size: 12), lineHeight: 14) }
}
