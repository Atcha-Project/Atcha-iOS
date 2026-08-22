import UIKit

// Non-crashing counterpart to the Tuist-generated Bundle.module accessor:
// static-framework resources land in DesignSystem_DesignSystem.bundle inside
// the host product, but hostless unit tests have no host app and the generated
// accessor fatalErrors. Returning nil lets every token fall back gracefully.
enum DSResourceBundle {
    private final class Token {}

    static let current: Bundle? = {
        let bundleName = "DesignSystem_DesignSystem.bundle"
        let candidates: [URL?] = [
            Bundle.main.resourceURL,
            Bundle(for: Token.self).resourceURL,
            Bundle.main.bundleURL,
            // Hostless test runners put the bundle next to the xctest bundle
            // (one directory up in BUILT_PRODUCTS_DIR).
            Bundle(for: Token.self).resourceURL?.appendingPathComponent(".."),
        ]
        for candidate in candidates {
            guard let url = candidate?.appendingPathComponent(bundleName) else { continue }
            if let bundle = Bundle(url: url) { return bundle }
        }
        return nil
    }()
}
