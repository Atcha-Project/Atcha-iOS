@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSChipTests {
    @Test
    func setTextUpdatesTitle() {
        let chip = DSChip()
        chip.setText("→ 신림동")
        #expect(chip.configuration?.title == "→ 신림동")
        chip.setText("→ 강남역")
        #expect(chip.configuration?.title == "→ 강남역")
    }

    @Test
    func enabledUsesSecondaryColors() {
        let chip = DSChip()
        let configuration = chip.configuration
        #expect(configuration?.baseBackgroundColor.map {
            colorsMatch($0, DSColor.Fill.elevated)
        } == true)
        #expect(configuration?.baseForegroundColor.map {
            colorsMatch($0, DSColor.Text.primary)
        } == true)
    }

    @Test
    func disabledAppearanceMutesColors() {
        var configuration = UIButton.Configuration.filled()
        DSChip.applyColors(&configuration, isEnabled: false)
        #expect(configuration.baseBackgroundColor.map {
            colorsMatch($0, DSColor.Fill.surface)
        } == true)
        #expect(configuration.baseForegroundColor.map {
            colorsMatch($0, DSColor.Text.disabled)
        } == true)
    }

    @Test
    func pillShapeIsFixedHeight() {
        let chip = DSChip()
        #expect(chip.intrinsicContentSize.height == 32)
        #expect(chip.configuration?.background.cornerRadius == DSRadius.lg)
    }
}
