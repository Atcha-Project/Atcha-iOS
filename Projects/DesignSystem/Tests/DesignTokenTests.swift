@testable import DesignSystem
import Testing

// Token-only assertions — resource-bundle lookup in hostless unit tests is
// unreliable for static frameworks, so no color asset access here.
@MainActor
struct DesignTokenTests {
    @Test
    func spacingScaleIsAscending() {
        #expect(DSSpacing.xs < DSSpacing.sm)
        #expect(DSSpacing.sm < DSSpacing.md)
        #expect(DSSpacing.md < DSSpacing.lg)
        #expect(DSSpacing.lg < DSSpacing.xl)
    }
}
