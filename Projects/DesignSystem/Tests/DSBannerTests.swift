@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSBannerTests {
    @Test
    func configureSetsText() {
        let banner = DSBanner()
        banner.configure(text: "막차 출발까지 42분")
        #expect(renderedTexts(in: banner).contains("막차 출발까지 42분"))
    }

    @Test
    func normalStyleUsesAccentContainer() {
        let banner = DSBanner(text: "막차 출발까지 42분", style: .normal)
        #expect(banner.backgroundColor.map {
            colorsMatch($0, DSColor.Accent.container)
        } == true)
    }

    @Test
    func urgentStyleUsesUrgentState() {
        let banner = DSBanner(text: "막차 출발까지 5분", style: .urgent)
        #expect(banner.backgroundColor.map {
            colorsMatch($0, DSColor.State.urgent)
        } == true)
    }
}
