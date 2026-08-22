import UIKit

public final class DSListCell: UITableViewCell {
    public enum Accessory: Equatable {
        case none
        case chevron
        case value(String)
        case delete
    }

    public struct Content {
        public let leadingIcon: UIImage?
        public let title: String
        public let subtitle: String?
        public let accessory: Accessory

        public init(
            leadingIcon: UIImage? = nil,
            title: String,
            subtitle: String? = nil,
            accessory: Accessory = .none
        ) {
            self.leadingIcon = leadingIcon
            self.title = title
            self.subtitle = subtitle
            self.accessory = accessory
        }
    }

    public static let reuseIdentifier = "DSListCell"
    public static let rowHeight: CGFloat = 56

    public var onDeleteTap: (() -> Void)?

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack = UIStackView()
    private let accessoryStack = UIStackView()
    private let rowStack = UIStackView()

    // UITableView dequeue requires this initializer — the one sanctioned
    // deviation from the designated-init convention.
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        let selected = UIView()
        selected.backgroundColor = DSColor.Fill.highlight
        selectedBackgroundView = selected

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = DSColor.Icon.muted
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: DSIconSize.md),
            iconView.heightAnchor.constraint(equalToConstant: DSIconSize.md),
        ])

        titleLabel.font = DSTypography.body2.font
        titleLabel.textColor = DSColor.Text.primary
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.font = DSTypography.caption1.font
        subtitleLabel.textColor = DSColor.Text.secondary
        subtitleLabel.lineBreakMode = .byTruncatingTail

        textStack.axis = .vertical
        textStack.spacing = DSSpacing.xxs
        [titleLabel, subtitleLabel].forEach(textStack.addArrangedSubview)

        accessoryStack.axis = .horizontal
        accessoryStack.alignment = .center

        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = DSSpacing.sm12
        [iconView, textStack, accessoryStack].forEach(rowStack.addArrangedSubview)

        rowStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: DSSpacing.md),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -DSSpacing.md),
            rowStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.rowHeight),
        ])
    }

    public func configure(with content: Content) {
        iconView.image = content.leadingIcon?.withRenderingMode(.alwaysTemplate)
        iconView.isHidden = content.leadingIcon == nil
        titleLabel.text = content.title
        subtitleLabel.text = content.subtitle
        subtitleLabel.isHidden = content.subtitle == nil
        applyAccessory(content.accessory)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        onDeleteTap = nil
        applyAccessory(.none)
    }

    private func applyAccessory(_ accessory: Accessory) {
        accessoryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        switch accessory {
        case .none:
            accessoryStack.isHidden = true
        case .chevron:
            accessoryStack.isHidden = false
            let chevron = UIImageView(image: DSIcon.chevronRight16.withRenderingMode(.alwaysTemplate))
            chevron.tintColor = DSColor.Text.secondary
            chevron.contentMode = .scaleAspectFit
            chevron.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                chevron.widthAnchor.constraint(equalToConstant: DSIconSize.sm),
                chevron.heightAnchor.constraint(equalToConstant: DSIconSize.sm),
            ])
            accessoryStack.addArrangedSubview(chevron)
        case .value(let value):
            accessoryStack.isHidden = false
            let label = UILabel()
            label.font = DSTypography.caption1.font
            label.textColor = DSColor.Text.secondary
            label.text = value
            accessoryStack.addArrangedSubview(label)
        case .delete:
            accessoryStack.isHidden = false
            let button = UIButton(type: .system)
            button.setImage(DSIcon.close24.withRenderingMode(.alwaysTemplate), for: .normal)
            button.tintColor = DSColor.Icon.default
            button.addAction(
                UIAction { [weak self] _ in self?.handleDeleteTap() },
                for: .touchUpInside
            )
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: DSIconSize.lg),
                button.heightAnchor.constraint(equalToConstant: DSIconSize.lg),
            ])
            accessoryStack.addArrangedSubview(button)
        }
    }

    // Internal so hostless tests can trigger the tap (sendActions needs a
    // running UIApplication).
    func handleDeleteTap() {
        onDeleteTap?()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
