import UIKit

public final class DSSectionHeader: UIView {
    public var onAction: (() -> Void)?

    private static let headerHeight: CGFloat = 40

    private let titleLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    public init(title: String, actionTitle: String? = nil) {
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = DSTypography.label2.font
        titleLabel.textColor = DSColor.Text.secondary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.md),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        actionButton.setAttributedTitle(
            NSAttributedString(
                string: actionTitle ?? "",
                attributes: [
                    .font: DSTypography.caption1.font,
                    .foregroundColor: DSColor.Text.secondary,
                ]
            ),
            for: .normal
        )
        actionButton.isHidden = actionTitle == nil
        actionButton.addAction(
            UIAction { [weak self] _ in self?.handleActionTap() },
            for: .touchUpInside
        )
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actionButton)
        NSLayoutConstraint.activate([
            actionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.md),
            actionButton.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Self.headerHeight)
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
