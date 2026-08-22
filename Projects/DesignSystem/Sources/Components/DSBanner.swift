import UIKit

// Countdown banner ("막차 출발까지 N분"). Rendering only — the 1-minute tick
// lives in the owning ViewModel, which calls configure on each update.
public final class DSBanner: UIView {
    public enum Style {
        case normal
        case urgent
    }

    private let label = UILabel()

    public init(text: String = "", style: Style = .normal) {
        super.init(frame: .zero)

        layer.cornerRadius = DSRadius.lg

        label.font = DSTypography.label1.font
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.md),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.md),
            label.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.sm12),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.sm12),
        ])

        configure(text: text, style: style)
    }

    public func configure(text: String, style: Style = .normal) {
        label.text = text
        switch style {
        case .normal:
            backgroundColor = DSColor.Accent.container
            label.textColor = DSColor.Accent.default
        case .urgent:
            backgroundColor = DSColor.State.urgent
            label.textColor = DSColor.Text.primary
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
