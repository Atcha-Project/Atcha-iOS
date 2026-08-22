import UIKit

// UI vocabulary for transit lines — not a Domain type. Features map their
// entities onto these cases; the palette mapping stays inside DesignSystem.
public enum DSSubwayLine: CaseIterable, Sendable {
    case line1, line2, line3, line4, line5, line6, line7, line8, line9
    case airport, gtxA, shinbundang, suinBundang
    case gyeongchun, gyeonguiJungang, gyeonggang
    case incheon1, incheon2
    case seohae, sillim, uiSinseol, uijeongbu, everline, gimpo

    public var color: UIColor {
        switch self {
        case .line1: DSPalette.Transport.subwayLine1
        case .line2: DSPalette.Transport.subwayLine2
        case .line3: DSPalette.Transport.subwayLine3
        case .line4: DSPalette.Transport.subwayLine4
        case .line5: DSPalette.Transport.subwayLine5
        case .line6: DSPalette.Transport.subwayLine6
        case .line7: DSPalette.Transport.subwayLine7
        case .line8: DSPalette.Transport.subwayLine8
        case .line9: DSPalette.Transport.subwayLine9
        case .airport: DSPalette.Transport.airport
        case .gtxA: DSPalette.Transport.gtxA
        case .shinbundang: DSPalette.Transport.shinbundang
        case .suinBundang: DSPalette.Transport.suinBundang
        case .gyeongchun: DSPalette.Transport.gyeongchun
        case .gyeonguiJungang: DSPalette.Transport.gyeonguiJungang
        case .gyeonggang: DSPalette.Transport.gyeonggang
        case .incheon1: DSPalette.Transport.incheon1
        case .incheon2: DSPalette.Transport.incheon2
        case .seohae: DSPalette.Transport.seohae
        case .sillim: DSPalette.Transport.sillim
        case .uiSinseol: DSPalette.Transport.uiSinseol
        case .uijeongbu: DSPalette.Transport.uijeongbu
        case .everline: DSPalette.Transport.everline
        case .gimpo: DSPalette.Transport.gimpo
        }
    }
}

public enum DSBusType: CaseIterable, Sendable {
    case general, mainline, regular, town, widearea

    public var color: UIColor {
        switch self {
        case .general: DSPalette.Transport.busGeneral
        case .mainline: DSPalette.Transport.busMainline
        case .regular: DSPalette.Transport.busRegular
        case .town: DSPalette.Transport.busTown
        case .widearea: DSPalette.Transport.busWidearea
        }
    }
}

public final class DSTransportBadge: UIView {
    public enum Kind: Equatable, Sendable {
        case subway(DSSubwayLine, text: String)
        case bus(DSBusType, text: String)
        case walk
    }

    private static let badgeHeight: CGFloat = 20

    private let label = UILabel()
    private var isCircular = false

    public init(kind: Kind) {
        super.init(frame: .zero)

        // Badges must keep their intrinsic width even inside fill-distribution
        // stacks (a stretched line badge reads as a different line).
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)

        label.font = DSTypography.caption2.font
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.xs),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.xs),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: Self.badgeHeight),
            widthAnchor.constraint(greaterThanOrEqualTo: heightAnchor),
        ])

        configure(kind: kind)
    }

    public func configure(kind: Kind) {
        switch kind {
        case .subway(let line, let text):
            backgroundColor = line.color
            label.text = text
            label.textColor = DSPalette.grey50
            isCircular = true
        case .bus(let type, let text):
            backgroundColor = type.color
            label.text = text
            label.textColor = DSPalette.grey50
            isCircular = false
        case .walk:
            backgroundColor = DSColor.Fill.elevated
            label.text = "도보"
            label.textColor = DSColor.Text.secondary
            isCircular = false
        }
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // Single-digit subway badges render as a circle; anything wider
        // (bus route numbers, named lines) becomes a pill.
        layer.cornerRadius = isCircular ? bounds.height / 2 : 6
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
