@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSTransportBadgeTests {
    @Test
    func subwayKindUsesLineColor() {
        let badge = DSTransportBadge(kind: .subway(.line2, text: "2"))
        #expect(badge.backgroundColor.map {
            colorsMatch($0, DSPalette.Transport.subwayLine2)
        } == true)
        #expect(renderedTexts(in: badge).contains("2"))
    }

    @Test
    func busKindUsesTypeColor() {
        let badge = DSTransportBadge(kind: .bus(.widearea, text: "9401"))
        #expect(badge.backgroundColor.map {
            colorsMatch($0, DSPalette.Transport.busWidearea)
        } == true)
        #expect(renderedTexts(in: badge).contains("9401"))
    }

    @Test
    func walkKindUsesNeutralFill() {
        let badge = DSTransportBadge(kind: .walk)
        #expect(badge.backgroundColor.map {
            colorsMatch($0, DSColor.Fill.elevated)
        } == true)
        #expect(renderedTexts(in: badge).contains("도보"))
    }

    @Test
    func everySubwayLineMapsToADistinctColorToken() {
        for line in DSSubwayLine.allCases {
            let (_, _, _, alpha) = rgba(line.color)
            #expect(alpha == 1.0)
        }
    }
}
