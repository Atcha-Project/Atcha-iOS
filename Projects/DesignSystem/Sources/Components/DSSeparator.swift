import UIKit

public final class DSSeparator: UIView {
    public enum Axis {
        case horizontal
        case vertical
    }

    private static let thickness: CGFloat = 0.5

    private let axis: Axis

    public init(axis: Axis = .horizontal) {
        self.axis = axis
        super.init(frame: .zero)
        backgroundColor = DSColor.Border.default
    }

    public override var intrinsicContentSize: CGSize {
        switch axis {
        case .horizontal:
            CGSize(width: UIView.noIntrinsicMetric, height: Self.thickness)
        case .vertical:
            CGSize(width: Self.thickness, height: UIView.noIntrinsicMetric)
        }
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
