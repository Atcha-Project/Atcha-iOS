@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DesignTokenTests {
    @Test
    func spacingScaleIsAscending() {
        #expect(DSSpacing.xxs < DSSpacing.xs)
        #expect(DSSpacing.xs < DSSpacing.sm)
        #expect(DSSpacing.sm < DSSpacing.sm12)
        #expect(DSSpacing.sm12 < DSSpacing.md)
        #expect(DSSpacing.md < DSSpacing.lg20)
        #expect(DSSpacing.lg20 < DSSpacing.lg)
        #expect(DSSpacing.lg < DSSpacing.xl)
    }

    @Test
    func radiusAndIconScales() {
        #expect(DSRadius.sm == 8)
        #expect(DSRadius.md == 12)
        #expect(DSRadius.lg == 16)
        #expect(DSIconSize.sm == 16)
        #expect(DSIconSize.md == 20)
        #expect(DSIconSize.lg == 24)
    }

    @Test
    func greyPaletteMatchesSpec() {
        #expect(colorMatchesHex(DSPalette.grey50, 0xFEFFFF))
        #expect(colorMatchesHex(DSPalette.grey100, 0xB9B9C2))
        #expect(colorMatchesHex(DSPalette.grey200, 0x999CA4))
        #expect(colorMatchesHex(DSPalette.grey300, 0x7E7E8A))
        #expect(colorMatchesHex(DSPalette.grey400, 0x666970))
        #expect(colorMatchesHex(DSPalette.grey500, 0x5B5B63))
        #expect(colorMatchesHex(DSPalette.grey600, 0x424249))
        #expect(colorMatchesHex(DSPalette.grey700, 0x36363A))
        #expect(colorMatchesHex(DSPalette.grey800, 0x2C2C2E))
        #expect(colorMatchesHex(DSPalette.grey850, 0x1F1F23))
        #expect(colorMatchesHex(DSPalette.grey900, 0x131315))
    }

    @Test
    func brandPaletteMatchesSpec() {
        #expect(colorMatchesHex(DSPalette.lime200, 0xC2FBAD))
        #expect(colorMatchesHex(DSPalette.lime400, 0x99F977))
        #expect(colorMatchesHex(DSPalette.lime600, 0x6FCC50))
        #expect(colorMatchesHex(DSPalette.lime900, 0x243C1B))
        #expect(colorMatchesHex(DSPalette.red400, 0xF24747))
        #expect(colorMatchesHex(DSPalette.red600, 0xAA3131))
        #expect(colorMatchesHex(DSPalette.whiteAlpha4, 0xFFFFFF, alpha: 0.04))
    }

    @Test
    func transportPaletteMatchesSpec() {
        #expect(colorMatchesHex(DSPalette.Transport.subwayLine1, 0x1777FF))
        #expect(colorMatchesHex(DSPalette.Transport.subwayLine2, 0x24B847))
        #expect(colorMatchesHex(DSPalette.Transport.subwayLine9, 0xD8A516))
        #expect(colorMatchesHex(DSPalette.Transport.shinbundang, 0xBF3649))
        #expect(colorMatchesHex(DSPalette.Transport.gtxA, 0x8F5787))
        #expect(colorMatchesHex(DSPalette.Transport.busGeneral, 0x009BA9))
        #expect(colorMatchesHex(DSPalette.Transport.busWidearea, 0xF24747))
        #expect(colorMatchesHex(DSPalette.Transport.neutral, 0x393C42))
    }

    @Test
    func semanticTokensResolveToPaletteSlots() {
        #expect(colorsMatch(DSColor.Background.base, DSPalette.grey900))
        #expect(colorsMatch(DSColor.Background.elevated, DSPalette.grey850))
        #expect(colorsMatch(DSColor.Fill.surface, DSPalette.grey850))
        #expect(colorsMatch(DSColor.Fill.elevated, DSPalette.grey800))
        #expect(colorsMatch(DSColor.Fill.highlight, DSPalette.whiteAlpha4))
        #expect(colorsMatch(DSColor.Text.primary, DSPalette.grey50))
        #expect(colorsMatch(DSColor.Text.secondary, DSPalette.grey400))
        #expect(colorsMatch(DSColor.Text.tertiary, DSPalette.grey500))
        #expect(colorsMatch(DSColor.Text.disabled, DSPalette.grey600))
        #expect(colorMatchesHex(DSColor.Text.onAccent, 0x000000))
        #expect(colorsMatch(DSColor.Icon.default, DSPalette.grey200))
        #expect(colorsMatch(DSColor.Icon.muted, DSPalette.grey400))
        #expect(colorsMatch(DSColor.Border.default, DSPalette.grey700))
        #expect(colorsMatch(DSColor.Border.focused, DSPalette.lime400))
        #expect(colorsMatch(DSColor.Accent.default, DSPalette.lime400))
        #expect(colorsMatch(DSColor.Accent.pressed, DSPalette.lime600))
        #expect(colorsMatch(DSColor.Accent.container, DSPalette.lime900))
        #expect(colorsMatch(DSColor.Accent.tint, DSPalette.lime200))
        #expect(colorsMatch(DSColor.State.danger, DSPalette.red400))
        #expect(colorsMatch(DSColor.State.urgent, DSPalette.red600))
    }
}
