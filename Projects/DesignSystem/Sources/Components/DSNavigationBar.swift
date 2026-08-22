import UIKit

public final class DSNavigationBar: UIView {
    public enum Style {
        case title(String)
        case backOnly
        case search(placeholder: String)
    }

    public var onBack: (() -> Void)?

    // Exposed for the .search style so callers can wire text callbacks.
    public private(set) var searchField: DSTextField?

    private static let barHeight: CGFloat = 56

    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()

    public init(style: Style) {
        super.init(frame: .zero)

        backgroundColor = DSColor.Background.base

        backButton.setImage(DSIcon.back24.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = DSColor.Icon.default
        backButton.addAction(
            UIAction { [weak self] _ in self?.handleBackTap() },
            for: .touchUpInside
        )
        backButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.md),
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: DSIconSize.lg),
            backButton.heightAnchor.constraint(equalToConstant: DSIconSize.lg),
        ])

        switch style {
        case .title(let title):
            titleLabel.text = title
            titleLabel.font = DSTypography.heading.font
            titleLabel.textColor = DSColor.Text.primary
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(titleLabel)
            NSLayoutConstraint.activate([
                titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
        case .backOnly:
            break
        case .search(let placeholder):
            let field = DSTextField(placeholder: placeholder)
            field.translatesAutoresizingMaskIntoConstraints = false
            addSubview(field)
            NSLayoutConstraint.activate([
                field.leadingAnchor.constraint(
                    equalTo: backButton.trailingAnchor, constant: DSSpacing.sm12
                ),
                field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.md),
                field.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])
            searchField = field
        }
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.barHeight)
    }

    // Internal so hostless tests can trigger the tap (sendActions needs a
    // running UIApplication).
    func handleBackTap() {
        onBack?()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
