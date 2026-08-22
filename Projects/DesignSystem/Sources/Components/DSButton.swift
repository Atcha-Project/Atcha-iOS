import UIKit

public final class DSButton: UIButton {
    public enum Style {
        case primary
        case secondary
        case line
        case text
    }

    public enum Size {
        case large
        case medium
        case small

        var height: CGFloat {
            switch self {
            case .large: 52
            case .medium: 44
            case .small: 32
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .large: DSRadius.lg
            case .medium: DSRadius.md
            case .small: DSRadius.sm
            }
        }

        var font: UIFont {
            switch self {
            case .large: DSTypography.heading.font
            case .medium: DSTypography.label1.font
            case .small: DSTypography.label2.font
            }
        }
    }

    private let size: Size

    public init(title: String, style: Style = .primary, size: Size = .large, icon: UIImage? = nil) {
        self.size = size
        super.init(frame: .zero)

        var configuration: UIButton.Configuration = switch style {
        case .primary, .secondary: .filled()
        case .line, .text: .plain()
        }
        configuration.attributedTitle = AttributedString(
            title, attributes: AttributeContainer([.font: size.font])
        )
        configuration.background.cornerRadius = size.cornerRadius
        configuration.cornerStyle = .fixed
        configuration.contentInsets = .init(
            top: 0, leading: DSSpacing.md, bottom: 0, trailing: DSSpacing.md
        )
        if let icon {
            configuration.image = icon.withRenderingMode(.alwaysTemplate)
            configuration.imagePadding = 6
        }
        // Colors are applied eagerly so the initial configuration is complete
        // without waiting for an update pass (which never runs in hostless
        // tests); the update handler keeps them in sync with state changes.
        Self.applyColors(&configuration, style: style, isEnabled: true, isHighlighted: false)
        self.configuration = configuration

        configurationUpdateHandler = { [style] button in
            guard var configuration = button.configuration else { return }
            Self.applyColors(
                &configuration,
                style: style,
                isEnabled: button.isEnabled,
                isHighlighted: button.isHighlighted
            )
            button.configuration = configuration
        }
    }

    static func applyColors(
        _ configuration: inout UIButton.Configuration,
        style: Style,
        isEnabled: Bool,
        isHighlighted: Bool
    ) {
        guard isEnabled else {
            configuration.baseBackgroundColor =
                (style == .primary || style == .secondary) ? DSColor.Fill.surface : .clear
            configuration.baseForegroundColor = DSColor.Text.disabled
            configuration.background.strokeWidth = 0
            return
        }
        switch style {
        case .primary:
            configuration.baseBackgroundColor =
                isHighlighted ? DSColor.Accent.pressed : DSColor.Accent.default
            configuration.baseForegroundColor = DSColor.Text.onAccent
        case .secondary:
            configuration.baseBackgroundColor = DSColor.Fill.elevated
            configuration.baseForegroundColor = DSColor.Text.primary
        case .line:
            configuration.baseBackgroundColor = .clear
            configuration.baseForegroundColor = DSColor.Text.primary
            configuration.background.strokeColor = DSColor.Border.default
            configuration.background.strokeWidth = 1
        case .text:
            configuration.baseBackgroundColor = .clear
            configuration.baseForegroundColor = DSColor.Accent.default
        }
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: super.intrinsicContentSize.width, height: size.height)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
