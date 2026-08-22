import UIKit

public enum DSColor {
    public static var accent: UIColor { asset("dsAccent", fallback: .systemIndigo) }
    public static var background: UIColor { asset("dsBackground", fallback: .systemBackground) }
    public static var textPrimary: UIColor { asset("dsTextPrimary", fallback: .label) }

    private static func asset(_ name: String, fallback: UIColor) -> UIColor {
        UIColor(named: name, in: .module, compatibleWith: nil) ?? fallback
    }
}
