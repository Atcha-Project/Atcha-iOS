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
    func cautionStyleUsesDangerContainer() {
        let banner = DSBanner(text: "출발까지 25분", style: .caution)
        #expect(banner.backgroundColor.map {
            colorsMatch($0, DSColor.State.dangerContainer)
        } == true)
    }

    @Test
    func urgentStyleUsesUrgentState() {
        let banner = DSBanner(text: "막차 출발까지 5분", style: .urgent)
        #expect(banner.backgroundColor.map {
            colorsMatch($0, DSColor.State.urgent)
        } == true)
    }

    @Test
    func emphasizeKeepsConfiguredContent() {
        // 강조는 1회 펄스일 뿐 — 텍스트·스타일 상태를 바꾸지 않는다.
        let banner = DSBanner(text: "출발까지 25분", style: .caution)
        banner.emphasize()
        #expect(renderedTexts(in: banner).contains("출발까지 25분"))
        #expect(banner.backgroundColor.map {
            colorsMatch($0, DSColor.State.dangerContainer)
        } == true)
    }
}
