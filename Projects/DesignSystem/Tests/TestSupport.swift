@testable import DesignSystem
import UIKit

// Every assertion in this target must also hold on the fallback path
// (no resource bundle): DSPalette fallback hex values are identical to the
// asset catalog, so color checks are deterministic either way.

func rgba(_ color: UIColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        .getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return (red, green, blue, alpha)
}

func colorsMatch(_ lhs: UIColor, _ rhs: UIColor, tolerance: CGFloat = 0.001) -> Bool {
    let l = rgba(lhs)
    let r = rgba(rhs)
    return abs(l.red - r.red) <= tolerance
        && abs(l.green - r.green) <= tolerance
        && abs(l.blue - r.blue) <= tolerance
        && abs(l.alpha - r.alpha) <= tolerance
}

func colorMatchesHex(
    _ color: UIColor, _ hex: UInt32, alpha: CGFloat = 1.0, tolerance: CGFloat = 0.001
) -> Bool {
    colorsMatch(color, UIColor(hex: hex, alpha: alpha), tolerance: tolerance)
}

@MainActor
func labels(in view: UIView) -> [UILabel] {
    var result: [UILabel] = []
    if let label = view as? UILabel { result.append(label) }
    for subview in view.subviews {
        result.append(contentsOf: labels(in: subview))
    }
    return result
}

@MainActor
func renderedTexts(in view: UIView) -> [String] {
    labels(in: view).compactMap { $0.text ?? $0.attributedText?.string }
}
