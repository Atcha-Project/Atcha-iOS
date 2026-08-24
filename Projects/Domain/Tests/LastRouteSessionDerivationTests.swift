@testable import Domain
import Foundation
import Testing

private func leg(
    mode: TransportMode,
    sectionTime: Int = 600,
    departureTime: Date? = nil,
    routeName: String? = nil,
    isExpressSubway: Bool = false
) -> TransportLeg {
    TransportLeg(
        mode: mode, sectionTime: sectionTime, distance: 100, departureTime: departureTime,
        routeName: routeName, lineType: nil, start: nil, end: nil,
        subwayFinalStation: nil, subwayDirection: nil,
        isExpressSubway: isExpressSubway, isLastSubway: false
    )
}

private func route(legs: [TransportLeg]) -> LastRoute {
    LastRoute(
        id: "r", departureTime: Date(timeIntervalSince1970: 1_000), totalTime: 0,
        totalWalkTime: 0, transferCount: 0, totalDistance: 0, totalWalkDistance: 0, legs: legs
    )
}

struct LastRouteSessionDerivationTests {
    @Test
    func firstWalkSectionSeconds_takesFirstWalkLegOnly() {
        // 첫 .walk leg의 sectionTime — 뒤쪽 도보(환승·하차)는 반영하지 않는다.
        let sut = route(legs: [
            leg(mode: .walk, sectionTime: 120),
            leg(mode: .subway, routeName: "2호선"),
            leg(mode: .walk, sectionTime: 300),
        ])
        #expect(sut.firstWalkSectionSeconds == 120)
    }

    @Test
    func firstWalkSectionSeconds_noWalkLeg_isNil() {
        #expect(route(legs: [leg(mode: .bus, routeName: "간선:6411")]).firstWalkSectionSeconds == nil)
        #expect(route(legs: []).firstWalkSectionSeconds == nil)
    }

    @Test
    func firstWalkSectionSeconds_walkAfterTransit_stillCounts() {
        // "첫 .walk leg"는 위치와 무관하게 목록에서 처음 나오는 도보 구간이다 —
        // 문서 명세(route.legs의 첫 .walk leg sectionTime) 그대로.
        let sut = route(legs: [
            leg(mode: .subway, routeName: "2호선"),
            leg(mode: .walk, sectionTime: 240),
        ])
        #expect(sut.firstWalkSectionSeconds == 240)
    }

    @Test
    func boardingLeg_prefersLegWithDepartureTime() {
        let departure = Date(timeIntervalSince1970: 1_000)
        let sut = route(legs: [
            leg(mode: .walk),
            leg(mode: .bus, routeName: "간선:472"),
            leg(mode: .subway, departureTime: departure, routeName: "9호선"),
        ])
        #expect(sut.boardingLeg?.routeName == "9호선")
    }

    @Test
    func boardingLeg_fallsBackToFirstTransitLeg() {
        let sut = route(legs: [
            leg(mode: .walk),
            leg(mode: .bus, routeName: "간선:472"),
            leg(mode: .subway, routeName: "9호선"),
        ])
        #expect(sut.boardingLeg?.routeName == "간선:472")
    }

    @Test
    func sessionDisplayName_busParsesTypePrefix() {
        #expect(route(legs: [leg(mode: .bus, routeName: "간선:6411")]).sessionDisplayName == "6411번 버스")
        #expect(route(legs: [leg(mode: .bus, routeName: "472")]).sessionDisplayName == "472번 버스")
        #expect(route(legs: [leg(mode: .bus)]).sessionDisplayName == "버스")
    }

    @Test
    func sessionDisplayName_subwayKeepsLineName() {
        #expect(route(legs: [leg(mode: .subway, routeName: "2호선")]).sessionDisplayName == "2호선")
        #expect(
            route(legs: [leg(mode: .subway, routeName: "9호선", isExpressSubway: true)])
                .sessionDisplayName == "9호선 급행"
        )
        #expect(route(legs: [leg(mode: .subway)]).sessionDisplayName == "지하철")
    }

    @Test
    func sessionDisplayName_noTransitLeg_fallsBack() {
        #expect(route(legs: [leg(mode: .walk)]).sessionDisplayName == "막차")
        #expect(route(legs: []).sessionDisplayName == "막차")
    }
}
