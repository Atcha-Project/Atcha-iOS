@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSTypographyTests {
    @Test
    func presetsMatchScaleSpec() {
        let expected: [(DSTypography, CGFloat, CGFloat)] = [
            (.display, 40, 48),
            (.title1, 26, 34),
            (.title2, 22, 28),
            (.title3, 20, 25),
            (.heading, 17, 24),
            (.body1, 17, 24),
            (.body2, 15, 22),
            (.label1, 15, 20),
            (.label2, 14, 18),
            (.caption1, 13, 16),
            (.caption2, 12, 14),
        ]
        for (style, pointSize, lineHeight) in expected {
            #expect(style.font.pointSize == pointSize)
            #expect(style.lineHeight == lineHeight)
        }
    }

    @Test
    func attributedPinsLineHeightAndColor() {
        let style = DSTypography.body2
        let attributed = style.attributed("막차", color: DSColor.Text.secondary, alignment: .center)
        let attributes = attributed.attributes(at: 0, effectiveRange: nil)

        let paragraph = attributes[.paragraphStyle] as? NSParagraphStyle
        #expect(paragraph?.minimumLineHeight == style.lineHeight)
        #expect(paragraph?.maximumLineHeight == style.lineHeight)
        #expect(paragraph?.alignment == .center)

        let color = attributes[.foregroundColor] as? UIColor
        #expect(color.map { colorsMatch($0, DSColor.Text.secondary) } == true)
    }
}
