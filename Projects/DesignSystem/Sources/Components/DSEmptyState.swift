import UIKit

// Shared empty/error surface: last-train-ended, no-route, permission-denied.
public final class DSEmptyState: UIView {
    public struct Content {
        public let icon: UIImage?
        public let title: String
        public let message: String?
        public let actionTitle: String?

        public init(
            icon: UIImage? = nil,
            title: String,
            message: String? = nil,
            actionTitle: String? = nil
        ) {
            self.icon = icon
            self.title = title
            self.message = message
            self.actionTitle = actionTitle
        }
    }

    public var onAction: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let contentStack = UIStackView()
    private var actionButton: DSButton?

    public init(content: Content) {
        super.init(frame: .zero)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = DSColor.Text.secondary
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(lessThanOrEqualToConstant: 120),
            iconView.heightAnchor.constraint(lessThanOrEqualToConstant: 120),
        ])

        titleLabel.font = DSTypography.heading.font
        titleLabel.textColor = DSColor.Text.primary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = DSSpacing.md
        [iconView, titleLabel, messageLabel].forEach(contentStack.addArrangedSubview)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        configure(with: content)
    }

    public func configure(with content: Content) {
        iconView.image = content.icon
        iconView.isHidden = content.icon == nil

        titleLabel.text = content.title

        if let message = content.message {
            messageLabel.attributedText = DSTypography.body2.attributed(
                message, color: DSColor.Text.secondary, alignment: .center
            )
            messageLabel.isHidden = false
        } else {
            messageLabel.isHidden = true
        }

        // DSButton's title is init-only, so the action button is recreated on
        // every configure — cheap for an empty state that rarely re-renders.
        actionButton?.removeFromSuperview()
        actionButton = nil
        if let actionTitle = content.actionTitle {
            let button = DSButton(title: actionTitle, style: .secondary, size: .medium)
            button.addAction(
                UIAction { [weak self] _ in self?.handleActionTap() },
                for: .touchUpInside
            )
            contentStack.addArrangedSubview(button)
            actionButton = button
        }
    }

    // Internal so hostless tests can trigger the tap (sendActions needs a
    // running UIApplication).
    func handleActionTap() {
        onAction?()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
