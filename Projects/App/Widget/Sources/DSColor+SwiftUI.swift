import DesignSystem
import SwiftUI
import UIKit

// DesignSystem is UIKit-based (UIColor role tokens). The widget extension is
// the repo's only SwiftUI surface, so the bridges (this color bridge and the
// DSFont+SwiftUI font bridge) live here instead of adding a SwiftUI dependency
// to DesignSystem itself.
extension Color {
    /// Bridges a DesignSystem `DSColor` token (UIColor) into SwiftUI,
    /// e.g. `Color(ds: DSColor.Accent.default)`.
    init(ds uiColor: UIColor) {
        self.init(uiColor: uiColor)
    }
}
