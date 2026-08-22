import UIKit

// Semantic color layer over DSPalette. Components use these role tokens only;
// raw palette slots stay an implementation detail behind them.
public enum DSColor {
    public enum Background {
        public static var base: UIColor { DSPalette.grey900 }
        public static var elevated: UIColor { DSPalette.grey850 }
    }

    public enum Fill {
        public static var surface: UIColor { DSPalette.grey850 }
        public static var elevated: UIColor { DSPalette.grey800 }
        public static var highlight: UIColor { DSPalette.whiteAlpha4 }
    }

    public enum Text {
        public static var primary: UIColor { DSPalette.grey50 }
        public static var secondary: UIColor { DSPalette.grey400 }
        public static var tertiary: UIColor { DSPalette.grey500 }
        public static var disabled: UIColor { DSPalette.grey600 }
        public static var onAccent: UIColor { UIColor(hex: 0x000000) }
    }

    public enum Icon {
        public static var `default`: UIColor { DSPalette.grey200 }
        public static var muted: UIColor { DSPalette.grey400 }
    }

    public enum Border {
        public static var `default`: UIColor { DSPalette.grey700 }
        public static var focused: UIColor { DSPalette.lime400 }
    }

    public enum Accent {
        public static var `default`: UIColor { DSPalette.lime400 }
        public static var pressed: UIColor { DSPalette.lime600 }
        public static var container: UIColor { DSPalette.lime900 }
        public static var tint: UIColor { DSPalette.lime200 }
    }

    public enum State {
        public static var danger: UIColor { DSPalette.red400 }
        public static var urgent: UIColor { DSPalette.red600 }
    }
}
