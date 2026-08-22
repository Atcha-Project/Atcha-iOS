@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSButtonTests {
    @Test
    func legacyTwoArgumentInitStillCompiles() {
        let button = DSButton(title: "새로고침", style: .secondary)
        #expect(button.configuration?.title == "새로고침")
    }

    @Test
    func primaryUsesAccentColors() {
        let button = DSButton(title: "등록", style: .primary)
        let configuration = button.configuration
        #expect(configuration?.baseBackgroundColor.map {
            colorsMatch($0, DSColor.Accent.default)
        } == true)
        #expect(configuration?.baseForegroundColor.map {
            colorsMatch($0, DSColor.Text.onAccent)
        } == true)
    }

    @Test
    func secondaryUsesElevatedFill() {
        let button = DSButton(title: "취소", style: .secondary)
        #expect(button.configuration?.baseBackgroundColor.map {
            colorsMatch($0, DSColor.Fill.elevated)
        } == true)
    }

    @Test
    func lineStyleStrokesBorder() {
        let button = DSButton(title: "더보기", style: .line)
        #expect(button.configuration?.background.strokeWidth == 1)
        #expect(button.configuration?.background.strokeColor.map {
            colorsMatch($0, DSColor.Border.default)
        } == true)
    }

    @Test
    func sizesDriveIntrinsicHeight() {
        #expect(DSButton(title: "a", size: .large).intrinsicContentSize.height == 52)
        #expect(DSButton(title: "a", size: .medium).intrinsicContentSize.height == 44)
        #expect(DSButton(title: "a", size: .small).intrinsicContentSize.height == 32)
    }

    @Test
    func disabledAppearanceMutesColors() {
        var configuration = UIButton.Configuration.filled()
        DSButton.applyColors(&configuration, style: .primary, isEnabled: false, isHighlighted: false)
        #expect(configuration.baseBackgroundColor.map {
            colorsMatch($0, DSColor.Fill.surface)
        } == true)
        #expect(configuration.baseForegroundColor.map {
            colorsMatch($0, DSColor.Text.disabled)
        } == true)
    }
}
