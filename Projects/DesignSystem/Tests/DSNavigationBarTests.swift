@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSNavigationBarTests {
    @Test
    func intrinsicHeightIs56() {
        let bar = DSNavigationBar(style: .backOnly)
        #expect(bar.intrinsicContentSize.height == 56)
    }

    @Test
    func titleStyleRendersCenteredTitle() {
        let bar = DSNavigationBar(style: .title("경로 상세"))
        #expect(renderedTexts(in: bar).contains("경로 상세"))
        #expect(bar.searchField == nil)
    }

    @Test
    func searchStyleExposesEmbeddedField() {
        let bar = DSNavigationBar(style: .search(placeholder: "장소 검색"))
        #expect(bar.searchField != nil)
    }

    @Test
    func backTapFiresCallback() {
        let bar = DSNavigationBar(style: .backOnly)
        var fired = false
        bar.onBack = { fired = true }
        bar.handleBackTap()
        #expect(fired)
    }
}
