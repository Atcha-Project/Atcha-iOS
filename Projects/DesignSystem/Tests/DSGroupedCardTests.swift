@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSGroupedCardTests {
    @Test
    func cardSurfaceAndRadius() {
        let card = DSGroupedCard(rows: [UIView(), UIView()])
        #expect(card.backgroundColor.map { colorsMatch($0, DSColor.Fill.surface) } == true)
        #expect(card.layer.cornerRadius == DSRadius.lg)
        #expect(card.clipsToBounds)
    }

    @Test
    func rowsAreInterleavedWithSeparators() throws {
        let rows = [UIView(), UIView(), UIView()]
        let card = DSGroupedCard(rows: rows)
        let stack = try #require(card.subviews.first as? UIStackView)
        // 행 3개 + 사이 구분선 2개 = 5, 순서는 행-선-행-선-행.
        #expect(stack.arrangedSubviews.count == 5)
        #expect(stack.arrangedSubviews[0] === rows[0])
        #expect(stack.arrangedSubviews[2] === rows[1])
        #expect(stack.arrangedSubviews[4] === rows[2])
    }

    @Test
    func separatorIsInsetHairline() throws {
        let card = DSGroupedCard(rows: [UIView(), UIView()])
        let stack = try #require(card.subviews.first as? UIStackView)
        let separatorContainer = stack.arrangedSubviews[1]
        let line = try #require(separatorContainer.subviews.first)
        #expect(line.backgroundColor.map { colorsMatch($0, DSColor.Border.default) } == true)
        let heightConstraint = line.constraints.first { $0.firstAttribute == .height }
        #expect(heightConstraint?.constant == 0.5)
        let leadingConstraint = separatorContainer.constraints.first {
            $0.firstAttribute == .leading || $0.secondAttribute == .leading
        }
        #expect(leadingConstraint?.constant == DSSpacing.md)
    }

    @Test
    func singleRowHasNoSeparator() throws {
        let card = DSGroupedCard(rows: [UIView()])
        let stack = try #require(card.subviews.first as? UIStackView)
        #expect(stack.arrangedSubviews.count == 1)
    }
}
