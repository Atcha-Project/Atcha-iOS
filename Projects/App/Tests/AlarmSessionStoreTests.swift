@testable import AtchaV2
import CoreStorage
import Domain
import Foundation
import Synchronization
import Testing

private final class InMemoryKeyValueStore: KeyValueStore {
    private let storage = Mutex<[String: Data]>([:])

    func data(forKey key: String) throws -> Data? { storage.withLock { $0[key] } }
    func set(_ data: Data, forKey key: String) throws { storage.withLock { $0[key] = data } }
    func removeValue(forKey key: String) throws { storage.withLock { $0[key] = nil } }
}

@MainActor
struct AlarmSessionStoreTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let store = InMemoryKeyValueStore()

    private func makeSUT() -> AlarmSessionStore {
        AlarmSessionStore(store: store)
    }

    private func session(
        route: String = "R1",
        departureOffset: TimeInterval = 900,
        walkSeconds: Int? = 300,
        lifecycle: AlarmSession.Lifecycle = .active
    ) -> AlarmSession {
        AlarmSession(
            server: AlarmInfo(
                lastRouteId: route,
                departureTime: now.addingTimeInterval(departureOffset),
                updatedAt: now,
                isReal: true
            ),
            local: .init(
                firstWalkSeconds: walkSeconds,
                routeDisplayName: "6411번 버스",
                transportMode: .bus
            ),
            lifecycle: lifecycle,
            syncedAt: now
        )
    }

    // MARK: - 부트스트랩

    @Test
    func bootstrap_emptyStore_currentIsNil() async {
        let sut = makeSUT()

        await sut.bootstrap()

        #expect(sut.current == nil)
    }

    /// 앱 시작 직후 디스크에서 복원해야 한다 — 이전 구조는 시딩이 `sync()` 안에 있어서
    /// sync가 돌지 않으면(오프라인 콜드스타트) 복원도 되지 않았다.
    @Test
    func bootstrap_restoresPersistedSession() async {
        let saved = session()
        try? store.setValue(saved, forKey: AlarmSessionStore.storageKey)
        let sut = makeSUT()

        await sut.bootstrap()

        #expect(sut.current == saved)
    }

    @Test
    func bootstrap_calledTwice_loadsOnce() async {
        try? store.setValue(session(), forKey: AlarmSessionStore.storageKey)
        let sut = makeSUT()
        await sut.bootstrap()

        // 두 번째 호출 전에 디스크를 비워도 캐시가 유지돼야 한다(재로드 금지).
        try? store.removeValue(forKey: AlarmSessionStore.storageKey)
        await sut.bootstrap()

        #expect(sut.current != nil)
    }

    // MARK: - Reconciler outcome 반영

    @Test
    func apply_refreshed_persistsAndExposes() async {
        let sut = makeSUT()
        await sut.bootstrap()
        let next = session()

        await sut.apply(.refreshed(next))

        #expect(sut.current == next)
        #expect((try? store.value(AlarmSession.self, forKey: AlarmSessionStore.storageKey)) == next)
    }

    /// 만료는 **지우지 않고 톰스톤을 남긴다** — 지우면 다음 실행에서 같은 과거 세션의
    /// refresh가 배너를 되살린다.
    @Test
    func apply_expired_keepsTombstoneOnDisk() async {
        let sut = makeSUT()
        await sut.bootstrap()
        let dead = session(lifecycle: .ended)

        await sut.apply(.expired(dead))

        #expect(sut.current?.lifecycle == .ended)
        let persisted = try? store.value(AlarmSession.self, forKey: AlarmSessionStore.storageKey)
        #expect(persisted?.lifecycle == .ended)
    }

    @Test
    func apply_ended_clearsEverything() async {
        let sut = makeSUT()
        await sut.register(session: session())

        await sut.apply(.ended)

        #expect(sut.current == nil)
        let persisted = try? store.value(AlarmSession.self, forKey: AlarmSessionStore.storageKey)
        #expect(persisted == nil)
    }

    /// 메아리는 상태를 바꾸지 않아야 한다.
    @Test
    func apply_ignoredStaleEcho_leavesStateUntouched() async {
        let sut = makeSUT()
        let existing = session()
        await sut.register(session: existing)

        await sut.apply(.ignoredStaleEcho)

        #expect(sut.current == existing)
    }

    // MARK: - 전이

    @Test
    func acknowledge_activeSession_transitionsToAcknowledged() async {
        let sut = makeSUT()
        await sut.register(session: session(lifecycle: .active))

        await sut.acknowledge()

        #expect(sut.current?.lifecycle == .acknowledged)
    }

    /// 이미 끝난 세션은 확인으로 되살아나면 안 된다.
    @Test
    func acknowledge_endedSession_isNoop() async {
        let sut = makeSUT()
        await sut.register(session: session(lifecycle: .ended))

        await sut.acknowledge()

        #expect(sut.current?.lifecycle == .ended)
    }

    /// 등록은 로컬 사실(도보 초)의 유일한 기록 시점이다.
    @Test
    func register_recordsLocalFacts() async {
        let sut = makeSUT()

        await sut.register(session: session(walkSeconds: 420))

        #expect(sut.current?.local.firstWalkSeconds == 420)
        // fireDate가 도보 초를 반영해야 한다 — 이게 없으면 알람이 늦게 울린다.
        #expect(
            sut.current?.fireDate
                == now.addingTimeInterval(900 - 420 - AlarmTiming.bufferSeconds)
        )
    }

    @Test
    func reset_clearsSession() async {
        let sut = makeSUT()
        await sut.register(session: session())

        await sut.reset()

        #expect(sut.current == nil)
    }

    // MARK: - 구독 (replay-1)

    /// 구독 전에 끝난 부트스트랩을 놓치지 않아야 한다.
    @Test
    func updates_replaysCurrentValueOnSubscribe() async {
        let sut = makeSUT()
        let existing = session()
        await sut.register(session: existing)

        var iterator = sut.updates().makeAsyncIterator()
        let first = await iterator.next()

        #expect(first == existing)
    }

    @Test
    func updates_emitsOnApply() async {
        let sut = makeSUT()
        await sut.bootstrap()
        var iterator = sut.updates().makeAsyncIterator()
        _ = await iterator.next() // replay(nil)

        let next = session()
        await sut.apply(.refreshed(next))

        #expect(await iterator.next() == next)
    }

    @Test
    func updates_emitsNilOnClear() async {
        let sut = makeSUT()
        await sut.register(session: session())
        var iterator = sut.updates().makeAsyncIterator()
        _ = await iterator.next() // replay(session)

        await sut.clear()

        let received = await iterator.next()
        #expect(received == AlarmSession?.none)
    }
}
