import UIKit

// Primitive color layer. Components never reference DSPalette directly —
// they go through the semantic DSColor tokens. Fallback hex values are kept
// identical to the asset catalog so every token resolves to the same color
// whether or not the resource bundle is reachable (e.g. hostless tests).
public enum DSPalette {
    public static var grey50: UIColor { asset("grey50", fallback: 0xFEFFFF) }
    public static var grey100: UIColor { asset("grey100", fallback: 0xB9B9C2) }
    public static var grey200: UIColor { asset("grey200", fallback: 0x999CA4) }
    public static var grey300: UIColor { asset("grey300", fallback: 0x7E7E8A) }
    public static var grey400: UIColor { asset("grey400", fallback: 0x666970) }
    public static var grey500: UIColor { asset("grey500", fallback: 0x5B5B63) }
    public static var grey600: UIColor { asset("grey600", fallback: 0x424249) }
    public static var grey700: UIColor { asset("grey700", fallback: 0x36363A) }
    public static var grey800: UIColor { asset("grey800", fallback: 0x2C2C2E) }
    public static var grey850: UIColor { asset("grey850", fallback: 0x1F1F23) }
    public static var grey900: UIColor { asset("grey900", fallback: 0x131315) }

    public static var lime200: UIColor { asset("lime200", fallback: 0xC2FBAD) }
    public static var lime400: UIColor { asset("lime400", fallback: 0x99F977) }
    public static var lime600: UIColor { asset("lime600", fallback: 0x6FCC50) }
    public static var lime900: UIColor { asset("lime900", fallback: 0x243C1B) }

    public static var red400: UIColor { asset("red400", fallback: 0xF24747) }
    public static var red600: UIColor { asset("red600", fallback: 0xAA3131) }

    public static var whiteAlpha4: UIColor { asset("whiteAlpha4", fallback: 0xFFFFFF, alpha: 0.04) }

    public enum Transport {
        public static var subwayLine1: UIColor { asset("transportSubwayLine1", fallback: 0x1777FF) }
        public static var subwayLine2: UIColor { asset("transportSubwayLine2", fallback: 0x24B847) }
        public static var subwayLine3: UIColor { asset("transportSubwayLine3", fallback: 0xED7B2A) }
        public static var subwayLine4: UIColor { asset("transportSubwayLine4", fallback: 0x3EB1FF) }
        public static var subwayLine5: UIColor { asset("transportSubwayLine5", fallback: 0x924FF6) }
        public static var subwayLine6: UIColor { asset("transportSubwayLine6", fallback: 0xC86E31) }
        public static var subwayLine7: UIColor { asset("transportSubwayLine7", fallback: 0x9BA81D) }
        public static var subwayLine8: UIColor { asset("transportSubwayLine8", fallback: 0xF54B90) }
        public static var subwayLine9: UIColor { asset("transportSubwayLine9", fallback: 0xD8A516) }
        public static var airport: UIColor { asset("transportAirport", fallback: 0x5CA9DB) }
        public static var gtxA: UIColor { asset("transportGtxA", fallback: 0x8F5787) }
        public static var shinbundang: UIColor { asset("transportShinbundang", fallback: 0xBF3649) }
        public static var suinBundang: UIColor { asset("transportSuinBundang", fallback: 0xDDB421) }
        public static var gyeongchun: UIColor { asset("transportGyeongchun", fallback: 0x2BBA8B) }
        public static var gyeonguiJungang: UIColor { asset("transportGyeonguiJungang", fallback: 0x3EADAD) }
        public static var gyeonggang: UIColor { asset("transportGyeonggang", fallback: 0x396CC3) }
        public static var incheon1: UIColor { asset("transportIncheon1", fallback: 0x71A4E6) }
        public static var incheon2: UIColor { asset("transportIncheon2", fallback: 0xD59F5E) }
        public static var seohae: UIColor { asset("transportSeohae", fallback: 0x90C939) }
        public static var sillim: UIColor { asset("transportSillim", fallback: 0x608CC4) }
        public static var uiSinseol: UIColor { asset("transportUiSinseol", fallback: 0xBBB51C) }
        public static var uijeongbu: UIColor { asset("transportUijeongbu", fallback: 0xE68E24) }
        public static var everline: UIColor { asset("transportEverline", fallback: 0x66BA60) }
        public static var gimpo: UIColor { asset("transportGimpo", fallback: 0x9F7A10) }
        public static var busGeneral: UIColor { asset("transportBusGeneral", fallback: 0x009BA9) }
        public static var busMainline: UIColor { asset("transportBusMainline", fallback: 0x1777FF) }
        public static var busRegular: UIColor { asset("transportBusRegular", fallback: 0x24B847) }
        public static var busTown: UIColor { asset("transportBusTown", fallback: 0x6FC53F) }
        public static var busWidearea: UIColor { asset("transportBusWidearea", fallback: 0xF24747) }
        public static var neutral: UIColor { asset("transportNeutral", fallback: 0x393C42) }
    }

    static func asset(_ name: String, fallback hex: UInt32, alpha: CGFloat = 1.0) -> UIColor {
        guard let bundle = DSResourceBundle.current,
              let color = UIColor(named: name, in: bundle, compatibleWith: nil) else {
            return UIColor(hex: hex, alpha: alpha)
        }
        return color
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}
