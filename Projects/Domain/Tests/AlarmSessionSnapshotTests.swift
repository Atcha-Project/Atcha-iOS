@testable import Domain
import Foundation
import Testing

struct AlarmSessionSnapshotTests {
    private let snapshot = AlarmSessionSnapshot(
        info: AlarmInfo(
            lastRouteId: "route-1",
            departureTime: Date(timeIntervalSince1970: 1_756_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_755_990_000),
            isReal: true
        ),
        firstWalkSeconds: 120,
        routeDisplayName: "6411번 버스",
        transportMode: .bus,
        acknowledged: false,
        expired: false
    )

    @Test
    func roundTripsCodable() throws {
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(AlarmSessionSnapshot.self, from: data)
        #expect(decoded == snapshot)
    }

    @Test
    func nilOptionalFields_roundTripCodable() throws {
        let sparse = AlarmSessionSnapshot(
            info: AlarmInfo(lastRouteId: "r", departureTime: nil, updatedAt: nil, isReal: false),
            firstWalkSeconds: nil,
            routeDisplayName: "",
            transportMode: nil,
            acknowledged: true,
            expired: true
        )
        let data = try JSONEncoder().encode(sparse)
        let decoded = try JSONDecoder().decode(AlarmSessionSnapshot.self, from: data)
        #expect(decoded == sparse)
        #expect(decoded.firstWalkSeconds == nil)
        #expect(decoded.transportMode == nil)
    }

    @Test
    func updating_replacesOnlyGivenFields() {
        let newInfo = AlarmInfo(
            lastRouteId: "route-1",
            departureTime: Date(timeIntervalSince1970: 1_756_000_600),
            updatedAt: nil,
            isReal: true
        )
        let updated = snapshot.updating(info: newInfo, acknowledged: true)
        // 세션 사실(도보·표시명·수단)은 유지된다.
        #expect(updated.info == newInfo)
        #expect(updated.acknowledged)
        #expect(!updated.expired)
        #expect(updated.firstWalkSeconds == 120)
        #expect(updated.routeDisplayName == "6411번 버스")
        #expect(updated.transportMode == .bus)

        let tombstone = snapshot.updating(expired: true)
        #expect(tombstone.expired)
        #expect(tombstone.info == snapshot.info)
    }
}
