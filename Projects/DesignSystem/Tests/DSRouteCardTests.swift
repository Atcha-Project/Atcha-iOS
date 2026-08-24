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

    @Test
    func mutedToneDimsLabelsAndRecoversOnNormal() {
        // "지난 막차" 등 비활성 표현(Phase 13) — muted 적용 후 normal 재구성 시 원복돼야
        // 한다(카드 재사용).
        let card = DSRouteCard()
        card.configure(
            with: .init(
                badgeText: "지난 막차",
                departureTimeText: "23:52 출발이었어요",
                legs: [.subway(.line2, text: "2")],
                tone: .muted
            )
        )
        let dimmed = labels(in: card)
        #expect(dimmed.first { $0.text == "23:52 출발이었어요" }?.textColor == DSColor.Text.secondary)
        #expect(dimmed.first { $0.text == "지난 막차" }?.textColor == DSColor.Text.secondary)
        #expect(allSubviews(of: card).contains { $0 is UIStackView && $0.alpha < 1 })

        card.configure(with: .init(departureTimeText: "23:52 출발", legs: [.walk]))
        let restored = labels(in: card)
        #expect(restored.first { $0.text == "23:52 출발" }?.textColor == DSColor.Text.primary)
        #expect(!allSubviews(of: card).contains { $0 is UIStackView && $0.alpha < 1 })
    }

    private func allSubviews(of view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap(allSubviews(of:))
    }
}
