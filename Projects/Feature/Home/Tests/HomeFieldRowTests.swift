import DesignSystem
@testable import HomeFeature
import Testing
import UIKit

@MainActor
struct HomeFieldRowTests {
    @Test
    func emptyTextShowsPlaceholderInSecondary() {
        let row = HomeFieldRow(icon: UIImage(), placeholder: "출발지를 검색해 주세요")
        let label = row.subviews.compactMap { $0 as? UILabel }.first
        #expect(label?.text == "출발지를 검색해 주세요")
        #expect(label.map { colorsMatch($0.textColor, DSColor.Text.secondary) } == true)
        #expect(row.accessibilityValue == nil)
    }

    @Test
    func valueShowsInPrimaryAndClearsBackToPlaceholder() {
        let row = HomeFieldRow(icon: UIImage(), placeholder: "출발지를 검색해 주세요")
        row.setText("강남역")
        let label = row.subviews.compactMap { $0 as? UILabel }.first
        #expect(label?.text == "강남역")
        #expect(label.map { colorsMatch($0.textColor, DSColor.Text.primary) } == true)
        #expect(row.accessibilityValue == "강남역")

        row.setText("")
        #expect(label?.text == "출발지를 검색해 주세요")
        #expect(label.map { colorsMatch($0.textColor, DSColor.Text.secondary) } == true)
    }

    @Test
    func rowHeightMatchesCardRowScale() {
        let row = HomeFieldRow(icon: UIImage(), placeholder: "출발지")
        let height = row.constraints.first { $0.firstAttribute == .height }
        #expect(height?.constant == 56)
    }

    @Test
    func rowIsAccessibleButton() {
        let row = HomeFieldRow(icon: UIImage(), placeholder: "도착지를 검색해 주세요")
        #expect(row.isAccessibilityElement)
        #expect(row.accessibilityTraits.contains(.button))
        #expect(row.accessibilityLabel == "도착지를 검색해 주세요")
    }
}

/// 토큰 색은 애셋 기반이라 인스턴스 비교가 불안정하다 — 다크 트레잇으로 해석해
/// RGBA를 비교한다(DesignSystem 테스트의 colorsMatch와 같은 방식).
@MainActor
private func colorsMatch(_ lhs: UIColor, _ rhs: UIColor) -> Bool {
    let trait = UITraitCollection(userInterfaceStyle: .dark)
    var l: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) = (0, 0, 0, 0)
    var r: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) = (0, 0, 0, 0)
    lhs.resolvedColor(with: trait).getRed(&l.red, green: &l.green, blue: &l.blue, alpha: &l.alpha)
    rhs.resolvedColor(with: trait).getRed(&r.red, green: &r.green, blue: &r.blue, alpha: &r.alpha)
    return abs(l.red - r.red) < 0.001
        && abs(l.green - r.green) < 0.001
        && abs(l.blue - r.blue) < 0.001
        && abs(l.alpha - r.alpha) < 0.001
}
