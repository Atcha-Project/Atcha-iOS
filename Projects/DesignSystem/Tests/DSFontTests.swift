@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSFontTests {
    @Test
    func pretendardReturnsRequestedPointSize() {
        for weight in DSFont.Weight.allCases {
            #expect(DSFont.pretendard(weight, size: 17).pointSize == 17)
        }
    }

    @Test
    func registrationResultMatchesFontAvailability() {
        // Coherence, not absolute availability: robust whether or not the
        // resource bundle resolves in this environment.
        let registered = DSFont.registerFontsIfNeeded()
        let resolvable = UIFont(name: "Pretendard-Regular", size: 17) != nil
        #expect(registered == resolvable)
    }
}
