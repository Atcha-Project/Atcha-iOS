import DesignSystem
import UIKit

final class ColorsDemoViewController: GalleryScreenViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionTitle("Semantic")
        let semantic: [(String, UIColor)] = [
            ("Background.base", DSColor.Background.base),
            ("Background.elevated", DSColor.Background.elevated),
            ("Fill.surface", DSColor.Fill.surface),
            ("Fill.elevated", DSColor.Fill.elevated),
            ("Fill.highlight", DSColor.Fill.highlight),
            ("Text.primary", DSColor.Text.primary),
            ("Text.secondary", DSColor.Text.secondary),
            ("Text.tertiary", DSColor.Text.tertiary),
            ("Text.disabled", DSColor.Text.disabled),
            ("Icon.default", DSColor.Icon.default),
            ("Icon.muted", DSColor.Icon.muted),
            ("Border.default", DSColor.Border.default),
            ("Border.focused", DSColor.Border.focused),
            ("Accent.default", DSColor.Accent.default),
            ("Accent.pressed", DSColor.Accent.pressed),
            ("Accent.container", DSColor.Accent.container),
            ("Accent.tint", DSColor.Accent.tint),
            ("State.danger", DSColor.State.danger),
            ("State.urgent", DSColor.State.urgent),
        ]
        semantic.forEach { contentStack.addArrangedSubview(swatch(name: $0.0, color: $0.1)) }

        addSectionTitle("Palette · grey")
        let greys: [(String, UIColor)] = [
            ("grey50", DSPalette.grey50), ("grey100", DSPalette.grey100),
            ("grey200", DSPalette.grey200), ("grey300", DSPalette.grey300),
            ("grey400", DSPalette.grey400), ("grey500", DSPalette.grey500),
            ("grey600", DSPalette.grey600), ("grey700", DSPalette.grey700),
            ("grey800", DSPalette.grey800), ("grey850", DSPalette.grey850),
            ("grey900", DSPalette.grey900),
        ]
        greys.forEach { contentStack.addArrangedSubview(swatch(name: $0.0, color: $0.1)) }

        addSectionTitle("Palette · lime / red")
        let brand: [(String, UIColor)] = [
            ("lime200", DSPalette.lime200), ("lime400", DSPalette.lime400),
            ("lime600", DSPalette.lime600), ("lime900", DSPalette.lime900),
            ("red400", DSPalette.red400), ("red600", DSPalette.red600),
        ]
        brand.forEach { contentStack.addArrangedSubview(swatch(name: $0.0, color: $0.1)) }
    }

    private func swatch(name: String, color: UIColor) -> UIView {
        let chip = UIView()
        chip.backgroundColor = color
        chip.layer.cornerRadius = DSRadius.sm
        chip.layer.borderWidth = 0.5
        chip.layer.borderColor = DSColor.Border.default.cgColor
        chip.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chip.widthAnchor.constraint(equalToConstant: 44),
            chip.heightAnchor.constraint(equalToConstant: 28),
        ])

        let label = UILabel()
        label.font = DSTypography.caption1.font
        label.textColor = DSColor.Text.primary
        label.text = name

        let row = UIStackView(arrangedSubviews: [chip, label])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = DSSpacing.sm12
        return row
    }
}

final class TypographyDemoViewController: GalleryScreenViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let presets: [(String, DSTypography)] = [
            ("display · EB40/48", .display),
            ("title1 · B26/34", .title1),
            ("title2 · B22/28", .title2),
            ("title3 · B20/25", .title3),
            ("heading · SB17/24", .heading),
            ("body1 · R17/24", .body1),
            ("body2 · R15/22", .body2),
            ("label1 · SB15/20", .label1),
            ("label2 · SB14/18", .label2),
            ("caption1 · R13/16", .caption1),
            ("caption2 · M12/14", .caption2),
        ]
        for (name, style) in presets {
            let label = UILabel()
            label.numberOfLines = 0
            label.attributedText = style.attributed(
                "막차 놓치지 마세요 · \(name)", color: DSColor.Text.primary
            )
            contentStack.addArrangedSubview(label)
        }
    }
}
