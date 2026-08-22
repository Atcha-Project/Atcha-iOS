@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSRouteCardTests {
    @Test
    func configureRendersAllContentFields() {
        let card = DSRouteCard()
        card.configure(
            with: .init(
                badgeText: "가장 늦은 차",
                departureTimeText: "23:52 출발",
                legs: [.subway(.line2, text: "2"), .bus(.mainline, text: "6411")],
                summaryText: "강남역 → 구로디지털단지",
                destinationText: "도착 00:41"
            )
        )
        let texts = renderedTexts(in: card)
        #expect(texts.contains("가장 늦은 차"))
        #expect(texts.contains("23:52 출발"))
        #expect(texts.contains("2"))
        #expect(texts.contains("6411"))
        #expect(texts.contains("강남역 → 구로디지털단지"))
        #expect(texts.contains("도착 00:41"))
    }

    @Test
    func legsStackContainsBadgesJoinedByChevrons() {
        let card = DSRouteCard()
        card.configure(
            with: .init(
                departureTimeText: "23:52",
                legs: [.subway(.line2, text: "2"), .subway(.line9, text: "9"), .walk]
            )
        )
        let badges = allSubviews(of: card).filter { $0 is DSTransportBadge }
        #expect(badges.count == 3)
    }

    @Test
    func nilFieldsHideTheirViews() {
        let card = DSRouteCard()
        card.configure(with: .init(departureTimeText: "23:52 출발"))
        let texts = renderedTexts(in: card)
        #expect(texts.contains("23:52 출발"))
        #expect(!texts.contains("가장 늦은 차"))

        let hidden = labels(in: card).filter(\.isHidden)
        #expect(!hidden.isEmpty)
    }

    private func allSubviews(of view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap(allSubviews(of:))
    }
}
