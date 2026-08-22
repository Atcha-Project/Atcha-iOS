import UIKit

// Brand glyphs from the asset catalog, with SF Symbol stand-ins when the
// bundle (or a specific asset) is unreachable — same resilience contract as
// the color tokens.
public enum DSIcon {
    public static var back24: UIImage { asset("icBack24", fallback: "chevron.left") }
    public static var close24: UIImage { asset("icClose24", fallback: "xmark") }
    public static var search24: UIImage { asset("icSearch24", fallback: "magnifyingglass") }
    public static var clear16: UIImage { asset("icClear16", fallback: "xmark.circle.fill") }
    public static var chevronRight16: UIImage { asset("icChevronRight16", fallback: "chevron.right") }
    public static var myLocation24: UIImage { asset("icMyLocation24", fallback: "location.fill") }
    public static var place24: UIImage { asset("icPlace24", fallback: "mappin.and.ellipse") }
    public static var bell24: UIImage { asset("icBell24", fallback: "bell.fill") }
    public static var info16: UIImage { asset("icInfo16", fallback: "info.circle") }
    public static var check20: UIImage { asset("icCheck20", fallback: "checkmark") }
    public static var illustCharacterGray: UIImage { asset("illustCharacterGray", fallback: "tram.fill") }

    private static func asset(_ name: String, fallback systemName: String) -> UIImage {
        if let bundle = DSResourceBundle.current,
           let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
            return image
        }
        return UIImage(systemName: systemName) ?? UIImage()
    }
}
