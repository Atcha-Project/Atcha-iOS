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

/// 틱 콜백은 메인 액터 밖에서도 읽히므로 락으로 감싼다.
private final class ValueBox<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value
    init(_ value: Value) { self.value = value }
    func get() -> Value { lock.lock(); defer { lock.unlock() }; return value }
    func set(_ newValue: Value) { lock.lock(); value = newValue; lock.unlock() }
}

@MainActor
struct AlarmSessionStoreTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let store = InMemoryKeyValueStore()

    private func makeSUT(now: @escaping @Sendable () -> Date = { Date() }) -> AlarmSessionStore {
        AlarmSessionStore(store: store, now: now)
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

    // MARK: - 시계 틱
    //
    // 홈 ViewModel의 배너 타이머가 하던 일을 Store가 가져왔다 — 화면이 세션을 끝내는
    // 구조를 없애고, 홈이 떠 있지 않아도 만료가 감지되게 한다.

    /// 출발 + 유예가 지나면 틱이 세션을 끝내고 콜백으로 알린다.
    @Test
    func tick_pastDeparture_expiresAndNotifies() async {
        let sut = makeSUT(now: { self.now })
        // 이미 지난 막차 — 다음 틱에서 만료돼야 한다.
        await sut.register(session: session(departureOffset: -120))
        let expired = ValueBox<AlarmSession?>(nil)

        sut.startTicking(interval: .milliseconds(10)) { session in
            expired.set(session)
        }
        for _ in 0..<80 where expired.get() == nil { try? await Task.sleep(for: .milliseconds(10)) }
        sut.stopTicking()

        #expect(expired.get()?.lifecycle == .ended)
        #expect(sut.current?.lifecycle == .ended)
    }

    /// 살아 있는 세션은 끝내지 않는다 — 대신 매 틱 재방출해 "출발까지 N분"이 갱신된다.
    @Test
    func tick_liveSession_doesNotExpire() async {
        let sut = makeSUT(now: { self.now })
        await sut.register(session: session(departureOffset: 900))
        let expired = ValueBox<AlarmSession?>(nil)

        sut.startTicking(interval: .milliseconds(10)) { session in
            expired.set(session)
        }
        try? await Task.sleep(for: .milliseconds(120))
        sut.stopTicking()

        #expect(expired.get() == nil)
        #expect(sut.current?.lifecycle == .active)
    }

    /// 이미 끝난 세션을 반복 통지하면 구독자가 같은 종료를 여러 번 처리한다.
    @Test
    func tick_endedSession_doesNotNotifyAgain() async {
        let sut = makeSUT(now: { self.now })
        await sut.register(session: session(departureOffset: -120, lifecycle: .ended))
        let expired = ValueBox<AlarmSession?>(nil)

        sut.startTicking(interval: .milliseconds(10)) { session in
            expired.set(session)
        }
        try? await Task.sleep(for: .milliseconds(120))
        sut.stopTicking()

        #expect(expired.get() == nil)
    }

    // MARK: - 구독 (replay-1)
    //
    // 세션 그대로를 보는 내부 스트림. 홈이 보는 `AlarmSyncEvents.updates()`는 이 위에
    // 얹힌 매핑이고, 끝난 세션을 흘리지 않는다(아래 별도 검증).

    /// 구독 전에 끝난 부트스트랩을 놓치지 않아야 한다.
    @Test
    func updates_replaysCurrentValueOnSubscribe() async {
        let sut = makeSUT()
        let existing = session()
        await sut.register(session: existing)

        var iterator = sut.sessionUpdates().makeAsyncIterator()
        let first = await iterator.next()

        #expect(first == existing)
    }

    @Test
    func updates_emitsOnApply() async {
        let sut = makeSUT()
        await sut.bootstrap()
        var iterator = sut.sessionUpdates().makeAsyncIterator()
        _ = await iterator.next() // replay(nil)

        let next = session()
        await sut.apply(.refreshed(next))

        #expect(await iterator.next() == next)
    }

    /// 홈 계약(`AlarmSyncEvents`)은 **끝난 세션을 흘리지 않는다** — 죽은 세션으로
    /// 배너·해제 버튼이 복원되면 안 된다.
    @Test
    func syncEventsUpdates_skipsEndedSession() async {
        let sut = makeSUT()
        await sut.register(session: session(lifecycle: .ended))

        var iterator = sut.updates().makeAsyncIterator()
        // replay에 끝난 세션이 실리지 않으므로, 살아 있는 세션을 넣어야 값이 온다.
        await sut.apply(.refreshed(session(lifecycle: .active)))

        let update = await iterator.next()
        #expect(update?.info.lastRouteId == "R1")
    }

    @Test
    func syncEventsUpdates_carriesSyncedAtAsCheckedAt() async {
        let sut = makeSUT()
        await sut.register(session: session())

        var iterator = sut.updates().makeAsyncIterator()

        // 스탬프의 원천은 세션의 syncedAt이다 — 수신 시각이 아니다.
        #expect(await iterator.next()?.checkedAt == now)
    }

    @Test
    func updates_emitsNilOnClear() async {
        let sut = makeSUT()
        await sut.register(session: session())
        var iterator = sut.sessionUpdates().makeAsyncIterator()
        _ = await iterator.next() // replay(session)

        await sut.clear()

        let received = await iterator.next()
        #expect(received == AlarmSession?.none)
    }
}
