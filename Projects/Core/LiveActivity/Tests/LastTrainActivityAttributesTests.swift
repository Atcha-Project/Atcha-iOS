@testable import CoreLiveActivity
import Foundation
import Testing

struct LastTrainActivityAttributesTests {
    private let state = LastTrainActivityAttributes.ContentState(
        departureTime: Date(timeIntervalSince1970: 1_756_000_000),
        alarmTime: Date(timeIntervalSince1970: 1_755_999_820),
        urgency: .caution,
        changeBadgeExpiry: Date(timeIntervalSince1970: 1_755_999_000),
        status: .active
    )

    @Test
    func contentState_roundTripsCodable() throws {
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(LastTrainActivityAttributes.ContentState.self, from: data)
        #expect(decoded == state)
    }

    @Test
    func contentState_nilBadgeExpiry_roundTripsCodable() throws {
        let noBadge = LastTrainActivityAttributes.ContentState(
            departureTime: state.departureTime,
            alarmTime: state.alarmTime,
            urgency: .imminent,
            changeBadgeExpiry: nil,
            status: .missed
        )
        let data = try JSONEncoder().encode(noBadge)
        let decoded = try JSONDecoder().decode(LastTrainActivityAttributes.ContentState.self, from: data)
        #expect(decoded == noBadge)
        #expect(decoded.changeBadgeExpiry == nil)
    }

    @Test
    func attributes_roundTripCodable_preservesFixedSessionInfo() throws {
        let attributes = LastTrainActivityAttributes(routeId: "route-42", routeName: "9호선 급행")
        let data = try JSONEncoder().encode(attributes)
        let decoded = try JSONDecoder().decode(LastTrainActivityAttributes.self, from: data)
        #expect(decoded.routeId == "route-42")
        #expect(decoded.routeName == "9호선 급행")
    }

    @Test
    func urgencyAndStatus_rawValuesAreStable() {
        // Raw values ride inside ActivityKit's persisted state — renaming a
        // case is a wire-format break, not a refactor.
        #expect(LastTrainUrgency.relaxed.rawValue == "relaxed")
        #expect(LastTrainUrgency.caution.rawValue == "caution")
        #expect(LastTrainUrgency.imminent.rawValue == "imminent")
        #expect(LastTrainSessionStatus.active.rawValue == "active")
        #expect(LastTrainSessionStatus.departed.rawValue == "departed")
        #expect(LastTrainSessionStatus.missed.rawValue == "missed")
        #expect(LastTrainSessionStatus.serviceEnded.rawValue == "serviceEnded")
    }

    @Test
    func contentState_departedStatus_roundTripsCodable() throws {
        // Phase 13 신설 케이스 — 앱(발신)·익스텐션(렌더) 사이 wire 왕복 확인.
        let departed = LastTrainActivityAttributes.ContentState(
            departureTime: state.departureTime,
            alarmTime: state.alarmTime,
            urgency: .imminent,
            changeBadgeExpiry: nil,
            status: .departed
        )
        let data = try JSONEncoder().encode(departed)
        let decoded = try JSONDecoder().decode(
            LastTrainActivityAttributes.ContentState.self, from: data
        )
        #expect(decoded == departed)
        #expect(decoded.status == .departed)
    }
}
