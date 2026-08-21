import UIKit

public enum DSFont {
    public static func title(_ size: CGFloat = 22) -> UIFont {
        .systemFont(ofSize: size, weight: .bold)
    }

    public static func body(_ size: CGFloat = 16) -> UIFont {
        .systemFont(ofSize: size, weight: .regular)
    }

    public static func caption(_ size: CGFloat = 12) -> UIFont {
        .systemFont(ofSize: size, weight: .medium)
    }
}
