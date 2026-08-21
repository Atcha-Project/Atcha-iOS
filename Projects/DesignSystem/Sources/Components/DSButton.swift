import UIKit

public final class DSButton: UIButton {
    public enum Style {
        case primary
        case secondary
    }

    public init(title: String, style: Style = .primary) {
        super.init(frame: .zero)
        var configuration: UIButton.Configuration = (style == .primary) ? .filled() : .gray()
        configuration.title = title
        configuration.cornerStyle = .large
        if style == .primary {
            configuration.baseBackgroundColor = DSColor.accent
        }
        configuration.contentInsets = .init(
            top: DSSpacing.sm, leading: DSSpacing.md,
            bottom: DSSpacing.sm, trailing: DSSpacing.md
        )
        self.configuration = configuration
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
