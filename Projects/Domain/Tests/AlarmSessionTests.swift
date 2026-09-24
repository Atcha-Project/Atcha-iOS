@testable import Domain
import Foundation
import Testing

/// `AlarmSessionSnapshotTests`가 검증하던 성질(Codable 왕복·부분 갱신·`syncedAt` 보존·
/// 하위호환)을 새 타입에서 이어간다. 영속 타입이라 디코딩이 깨지면 재실행 브리지가
/// 통째로 사라지므로 계약을 고정해 둔다.
struct AlarmSessionTests {
    private let session = AlarmSession(
        server: AlarmInfo(
            lastRouteId: "route-1",
            departureTime: Date(timeIntervalSince1970: 1_756_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_755_990_000),
            isReal: true
        ),
        local: .init(
            firstWalkSeconds: 120,
            routeDisplayName: "6411번 버스",
            transportMode: .bus
        ),
        lifecycle: .active,
        syncedAt: Date(timeIntervalSince1970: 1_755_995_000)
    )

    // MARK: - Codable

    @Test
    func roundTripsCodable() throws {
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(AlarmSession.self, from: data)
        #expect(decoded == session)
    }

    @Test
    func nilOptionalFields_roundTripCodable() throws {
        let sparse = AlarmSession(
            server: AlarmInfo(lastRouteId: "r", departureTime: nil, updatedAt: nil, isReal: false),
            local: .empty,
            lifecycle: .ended
        )
        let data = try JSONEncoder().encode(sparse)
        let decoded = try JSONDecoder().decode(AlarmSession.self, from: data)

        #expect(decoded == sparse)
        #expect(decoded.local.firstWalkSeconds == nil)
        #expect(decoded.local.transportMode == nil)
        #expect(decoded.syncedAt == nil)
    }

    /// 수명은 rawValue 문자열로 저장된다 — 케이스 이름을 바꾸면 기존 기록을 못 읽는다.
    @Test
    func lifecycle_encodesAsStableRawValue() throws {
        for (lifecycle, expected) in [
            (AlarmSession.Lifecycle.active, "active"),
            (.acknowledged, "acknowledged"),
            (.ended, "ended"),
        ] {
            let data = try JSONEncoder().encode(session.with(lifecycle: lifecycle))
            let object = try #require(
                try JSONSerialization.jsonObject(with: data) as? [String: Any]
            )
            #expect(object["lifecycle"] as? String == expected)
        }
    }

    // MARK: - 부분 갱신

    @Test
    func mergingSameRoute_replacesServerFactsAndKeepsLocalOnes() {
        let newServer = AlarmInfo(
            lastRouteId: "route-1",
            departureTime: Date(timeIntervalSince1970: 1_756_000_600),
            updatedAt: nil,
            isReal: true
        )

        let merged = session.merging(server: newServer, syncedAt: nil)

        #expect(merged.server == newServer)
        // 로컬 사실은 서버가 주지 않는 값이라 같은 경로면 반드시 보존돼야 한다.
        #expect(merged.local.firstWalkSeconds == 120)
        #expect(merged.local.routeDisplayName == "6411번 버스")
        #expect(merged.local.transportMode == .bus)
        #expect(merged.lifecycle == .active)
    }

    @Test
    func with_lifecycle_keepsEverythingElse() {
        let tombstone = session.with(lifecycle: .ended)

        #expect(tombstone.lifecycle == .ended)
        #expect(tombstone.server == session.server)
        #expect(tombstone.local == session.local)
    }

    // MARK: - syncedAt (신선도 스탬프)

    /// 톰스톤 전환이 스탬프를 지우거나 "지금"으로 바꾸면 사용자에게 거짓말이 된다.
    @Test
    func with_lifecycle_preservesSyncedAt() {
        #expect(session.with(lifecycle: .ended).syncedAt == session.syncedAt)
    }

    @Test
    func merging_withoutSyncedAt_preservesPrevious() {
        let merged = session.merging(server: session.server, syncedAt: nil)
        #expect(merged.syncedAt == session.syncedAt)
    }

    @Test
    func merging_withSyncedAt_updatesIt() {
        let checkedAt = Date(timeIntervalSince1970: 1_756_000_100)
        let merged = session.merging(server: session.server, syncedAt: checkedAt)
        #expect(merged.syncedAt == checkedAt)
    }

    /// 저장 포맷에서 키가 빠져도 디코딩이 깨지면 안 된다 — 재실행 브리지가 통째로
    /// 사라지는 것보다 스탬프를 잃는 쪽이 낫다.
    @Test
    func decoding_withoutSyncedAtKey_defaultsToNil() throws {
        var object = try #require(
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(session))
                as? [String: Any]
        )
        object.removeValue(forKey: "syncedAt")
        let data = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(AlarmSession.self, from: data)

        #expect(decoded.syncedAt == nil)
        #expect(decoded.server == session.server)
        #expect(decoded.local == session.local)
    }
}
