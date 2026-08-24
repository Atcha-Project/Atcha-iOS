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
        expired: false,
        syncedAt: Date(timeIntervalSince1970: 1_755_995_000)
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

    // MARK: - syncedAt (Phase 16 신선도 스탬프)

    @Test
    func updating_preservesSyncedAtUnlessGiven() {
        // 명시하지 않으면 마지막 확인 시각을 보존한다 — 톰스톤 전환이 스탬프를 지우면 안 된다.
        let tombstone = snapshot.updating(expired: true)
        #expect(tombstone.syncedAt == snapshot.syncedAt)

        let refreshed = snapshot.updating(syncedAt: Date(timeIntervalSince1970: 1_756_000_100))
        #expect(refreshed.syncedAt == Date(timeIntervalSince1970: 1_756_000_100))
        #expect(refreshed.info == snapshot.info)
    }

    @Test
    func decoding_snapshotWithoutSyncedAtKey_defaultsToNil() throws {
        // Phase 16 이전에 저장된 스냅샷(구 포맷) — syncedAt 키 부재는 nil로 디코딩돼야
        // 재실행 브리지가 깨지지 않는다(하위호환).
        let legacy = AlarmSessionSnapshot(
            info: snapshot.info,
            firstWalkSeconds: 120,
            routeDisplayName: "6411번 버스",
            transportMode: .bus,
            acknowledged: false,
            expired: false
        )
        var object = try #require(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as? [String: Any]
        )
        object.removeValue(forKey: "syncedAt")
        let data = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(AlarmSessionSnapshot.self, from: data)
        #expect(decoded.syncedAt == nil)
        #expect(decoded.info == snapshot.info)
    }
}
