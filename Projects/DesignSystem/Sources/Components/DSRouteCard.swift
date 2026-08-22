import UIKit

public final class DSRouteCard: UIView {
    public struct Content {
        public let badgeText: String?
        public let departureTimeText: String
        public let legs: [DSTransportBadge.Kind]
        public let summaryText: String?
        public let destinationText: String?

        public init(
            badgeText: String? = nil,
            departureTimeText: String,
            legs: [DSTransportBadge.Kind] = [],
            summaryText: String? = nil,
            destinationText: String? = nil
        ) {
            self.badgeText = badgeText
            self.departureTimeText = departureTimeText
            self.legs = legs
            self.summaryText = summaryText
            self.destinationText = destinationText
        }
    }

    private let badgeLabel = DSPaddedLabel(
        insets: .init(top: DSSpacing.xxs, left: DSSpacing.sm, bottom: DSSpacing.xxs, right: DSSpacing.sm)
    )
    private let departureTimeLabel = UILabel()
    private let legsStack = UIStackView()
    private let summaryLabel = UILabel()
    private let destinationLabel = UILabel()
    private let contentStack = UIStackView()

    public init() {
        super.init(frame: .zero)

        backgroundColor = DSColor.Fill.surface
        layer.cornerRadius = DSRadius.lg

        badgeLabel.font = DSTypography.caption2.font
        badgeLabel.textColor = DSColor.Accent.default
        badgeLabel.backgroundColor = DSColor.Accent.container
        badgeLabel.layer.cornerRadius = DSRadius.sm
        badgeLabel.clipsToBounds = true

        departureTimeLabel.font = DSTypography.title2.font
        departureTimeLabel.textColor = DSColor.Text.primary

        legsStack.axis = .horizontal
        legsStack.alignment = .center
        legsStack.spacing = DSSpacing.xs

        summaryLabel.font = DSTypography.body2.font
        summaryLabel.textColor = DSColor.Text.primary
        summaryLabel.numberOfLines = 0

        destinationLabel.font = DSTypography.caption1.font
        destinationLabel.textColor = DSColor.Text.secondary

        contentStack.axis = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = DSSpacing.sm
        [badgeLabel, departureTimeLabel, legsStack, summaryLabel, destinationLabel]
            .forEach(contentStack.addArrangedSubview)

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.md),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.md),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.md),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.md),
        ])
    }

    public func configure(with content: Content) {
        badgeLabel.text = content.badgeText
        badgeLabel.isHidden = content.badgeText == nil

        departureTimeLabel.text = content.departureTimeText

        legsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        legsStack.isHidden = content.legs.isEmpty
        for (index, kind) in content.legs.enumerated() {
            if index > 0 {
                let chevron = UIImageView(
                    image: DSIcon.chevronRight16.withRenderingMode(.alwaysTemplate)
                )
                chevron.tintColor = DSColor.Icon.muted
                chevron.contentMode = .scaleAspectFit
                chevron.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    chevron.widthAnchor.constraint(equalToConstant: DSIconSize.sm),
                    chevron.heightAnchor.constraint(equalToConstant: DSIconSize.sm),
                ])
                legsStack.addArrangedSubview(chevron)
            }
            legsStack.addArrangedSubview(DSTransportBadge(kind: kind))
        }

        summaryLabel.text = content.summaryText
        summaryLabel.isHidden = content.summaryText == nil

        destinationLabel.text = content.destinationText
        destinationLabel.isHidden = content.destinationText == nil
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

// UILabel with content insets — used for padded badge chips.
final class DSPaddedLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
