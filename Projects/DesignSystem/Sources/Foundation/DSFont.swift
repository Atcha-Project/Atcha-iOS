import CoreText
import UIKit

public enum DSFont {
    public enum Weight: String, CaseIterable {
        case regular = "Pretendard-Regular"
        case medium = "Pretendard-Medium"
        case semiBold = "Pretendard-SemiBold"
        case bold = "Pretendard-Bold"
        case extraBold = "Pretendard-ExtraBold"

        var systemWeight: UIFont.Weight {
            switch self {
            case .regular: .regular
            case .medium: .medium
            case .semiBold: .semibold
            case .bold: .bold
            case .extraBold: .heavy
            }
        }
    }

    public static func pretendard(_ weight: Weight, size: CGFloat) -> UIFont {
        registerFontsIfNeeded()
        return UIFont(name: weight.rawValue, size: size)
            ?? .systemFont(ofSize: size, weight: weight.systemWeight)
    }

    // One-shot CTFontManager registration. The module's resources live in a
    // nested bundle, so the app's UIAppFonts plist can't pick them up — the
    // fonts must be registered at runtime. Missing bundle or failed
    // registration silently falls back to the system font.
    @discardableResult
    public static func registerFontsIfNeeded() -> Bool {
        if didAttemptRegistration { return registrationSucceeded }
        didAttemptRegistration = true

        guard let bundle = DSResourceBundle.current else { return false }
        var urls = bundle.urls(forResourcesWithExtension: "otf", subdirectory: nil) ?? []
        urls += bundle.urls(forResourcesWithExtension: "otf", subdirectory: "Fonts") ?? []
        for url in urls {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // Already-registered (e.g. a host app also bundles Pretendard)
                // is not a failure; the font resolves either way.
                _ = error?.takeRetainedValue()
            }
        }
        registrationSucceeded = UIFont(name: Weight.regular.rawValue, size: 17) != nil
        return registrationSucceeded
    }

    private static var didAttemptRegistration = false
    private static var registrationSucceeded = false
}
