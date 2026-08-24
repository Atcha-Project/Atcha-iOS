@testable import AtchaV2
import Domain
import Foundation
import Testing

// AlarmSyncService(판정·폴백·만료 오케스트레이션)의 회귀 방어(Phase 16).
// 진입은 syncNow()(수동 갱신과 같은 경로 — NotificationCenter 없이 전 분기 도달),
// 시각·앱 활성 상태는 주입으로 고정한다(실 Date()·UIApplication 금지 규약).

private struct StubError: Error {}

private nonisolated let fixedNow = Date(timeIntervalSince1970: 1_755_800_000)

private nonisolated func info(route: String, departure: Date?) -> AlarmInfo {
    AlarmInfo(lastRouteId: route, departureTime: departure, updatedAt: nil, isReal: true)
}

/// 잠금 박스 — 테스트 도중 스텁 동작(활성 상태·판정)을 바꾼다.
private nonisolated final class ValueBox<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value
    init(_ value: Value) { self.value = value }
    func get() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
    func set(_ newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}

private final class RefreshStub: RefreshAlarmUseCase, @unchecked Sendable {
    private let lock = NSLock()
    private var queue: [Result<AlarmInfo, any Error>]
    init(_ results: [Result<AlarmInfo, any Error>]) { queue = results }
    func enqueue(_ result: Result<AlarmInfo, any Error>) {
        lock.lock()
        queue.append(result)
        lock.unlock()
    }
    // NSLock은 async 컨텍스트에서 직접 못 쓴다 — 동기 헬퍼로 분리.
    private func dequeue() -> Result<AlarmInfo, any Error>? {
        lock.lock()
        defer { lock.unlock() }
        return queue.isEmpty ? nil : queue.removeFirst()
    }
    func execute() async throws -> AlarmInfo {
        guard let next = dequeue() else { throw StubError() }
        return try next.get()
    }
}

/// 판정 고정 스텁 — 판정 로직 자체는 Domain 테스트 몫, 여기서는 분기만 본다.
private final class EvaluateStub: EvaluateAlarmChangeUseCase, @unchecked Sendable {
    private let lock = NSLock()
    private var verdict: AlarmChangeVerdict = .unchanged
    func fix(_ newVerdict: AlarmChangeVerdict) {
        lock.lock()
        verdict = newVerdict
        lock.unlock()
    }
    func execute(previous: AlarmInfo, latest: AlarmInfo, now: Date) -> AlarmChangeVerdict {
        lock.lock()
        defer { lock.unlock() }
        return verdict
    }
}

private actor ActivitySpy: LastTrainChangeAlerting {
    private var reachable = true
    private(set) var updates: [(state: LastTrainActivityState, alertTitle: String?)] = []
    private(set) var finals: [LastTrainActivityState] = []
    func setReachable(_ value: Bool) { reachable = value }
    var isDismissedByUser: Bool { !reachable }
    var isAlertReachable: Bool { reachable }
    func update(state: LastTrainActivityState, alert: (title: String, body: String)?) async {
        updates.append((state, alert?.title))
    }
    func end(final state: LastTrainActivityState) async {
        finals.append(state)
    }
    var alertCount: Int { updates.count { $0.alertTitle != nil } }
}

private actor NotiSpy: LocalNotificationPort {
    private(set) var posted: [String] = []
    @discardableResult
    func requestAuthorizationIfNeeded() async -> LocalNotificationAuthorizationOutcome {
        .alreadySettled
    }
    func post(title: String, body: String) async {
        posted.append(title)
    }
}

private actor SchedulerSpy: AlarmScheduler {
    private(set) var cancelCount = 0
    func requestAuthorization() async -> Bool { true }
    func replaceAlarm(id: String, fireDate: Date, title: String) async throws {}
    func cancelAlarm() async { cancelCount += 1 }
    func scheduledFireDate() async -> Date? { nil }
}

private actor StoreStub: AlarmSessionSnapshotStore {
    private(set) var snapshot: AlarmSessionSnapshot?
    init(_ snapshot: AlarmSessionSnapshot?) { self.snapshot = snapshot }
    func load() async -> AlarmSessionSnapshot? { snapshot }
    func save(_ snapshot: AlarmSessionSnapshot) async { self.snapshot = snapshot }
    func clear() async { snapshot = nil }
}

private actor RestorerSpy: LastTrainSessionRestoring {
    private(set) var restartCount = 0
    func reattachOrphans(snapshot: AlarmSessionSnapshot?, now: Date) async {}
    func restartIfNeeded(snapshot: AlarmSessionSnapshot, now: Date) async {
        restartCount += 1
    }
}

@MainActor
private struct Harness {
    let sut: AlarmSyncService
    let refresh: RefreshStub
    let evaluate: EvaluateStub
    let activity: ActivitySpy
    let noti: NotiSpy
    let scheduler: SchedulerSpy
    let store: StoreStub
    let active: ValueBox<Bool>

    /// 이전 값(diff 기준)을 심는 선행 동기화 — unchanged 판정으로 조용히 지나간다.
    func primePreviousSession(departure: Date) async {
        refresh.enqueue(.success(info(route: "r1", departure: departure)))
        await sut.syncNow()
    }
}

@MainActor
private func makeHarness(
    seeded: AlarmSessionSnapshot? = nil,
    isAppActive: Bool = false
) -> Harness {
    let refresh = RefreshStub([])
    let evaluate = EvaluateStub()
    let activity = ActivitySpy()
    let noti = NotiSpy()
    let scheduler = SchedulerSpy()
    let store = StoreStub(seeded)
    let restorer = RestorerSpy()
    let active = ValueBox(isAppActive)
    let sut = AlarmSyncService(
        refreshAlarmUseCase: refresh,
        evaluateChangeUseCase: evaluate,
        liveActivity: activity,
        localNotification: noti,
        alarmScheduler: scheduler,
        snapshotStore: store,
        sessionRestorer: restorer,
        isAppActive: { active.get() },
        now: { fixedNow }
    )
    return Harness(
        sut: sut, refresh: refresh, evaluate: evaluate, activity: activity,
        noti: noti, scheduler: scheduler, store: store, active: active
    )
}

@MainActor
struct AlarmSyncServiceTests {
    // MARK: - 신선도 스탬프 (Phase 16)

    @Test
    func syncSuccess_publishesCheckedAtAndPersistsSyncedAt() async {
        let harness = makeHarness()
        let departure = fixedNow.addingTimeInterval(3600)
        harness.refresh.enqueue(.success(info(route: "r1", departure: departure)))

        await harness.sut.syncNow()

        // replay-1이 확인 시각을 함께 나른다 — 스탬프의 원천은 sync 성공 시각(주입 now)뿐.
        var iterator = harness.sut.updates().makeAsyncIterator()
        let replayed = await iterator.next()
        #expect(replayed == AlarmSyncUpdate(
            info: info(route: "r1", departure: departure), checkedAt: fixedNow
        ))
        // 재실행 브리지에도 같은 시각이 영속화된다.
        #expect(await harness.store.snapshot?.syncedAt == fixedNow)
    }

    @Test
    func syncFailure_afterSeeding_replaysSnapshotConfirmedTime() async {
        // 재실행 + 오프라인: 시딩 복원값의 확인 시각은 "지금"이 아니라 스냅샷의
        // 마지막 확인 시각이어야 한다 — 낡음을 숨기지 않는다.
        let seededCheckedAt = fixedNow.addingTimeInterval(-2400)
        let departure = fixedNow.addingTimeInterval(1800)
        let harness = makeHarness(seeded: AlarmSessionSnapshot(
            info: info(route: "r1", departure: departure),
            firstWalkSeconds: nil,
            routeDisplayName: "6411번 버스",
            transportMode: .bus,
            acknowledged: false,
            expired: false,
            syncedAt: seededCheckedAt
        ))

        await harness.sut.syncNow() // refresh 큐 비어 있음 → 실패(무음)

        var iterator = harness.sut.updates().makeAsyncIterator()
        let replayed = await iterator.next()
        #expect(replayed?.info.lastRouteId == "r1")
        #expect(replayed?.checkedAt == seededCheckedAt)
    }

    // MARK: - advanced(actionable) 채널 분기 (Phase 11·12·15 회귀)

    @Test
    func advanced_background_reachable_sendsLiveActivityAlert() async {
        let harness = makeHarness(isAppActive: false)
        await harness.primePreviousSession(departure: fixedNow.addingTimeInterval(3600))

        harness.evaluate.fix(.advanced(by: 600, actionable: true))
        harness.refresh.enqueue(.success(info(route: "r1", departure: fixedNow.addingTimeInterval(3000))))
        await harness.sut.syncNow()

        #expect(await harness.activity.alertCount == 1)
        #expect(await harness.noti.posted.isEmpty)
    }

    @Test
    func advanced_background_unreachable_fallsBackToLocalNotification() async {
        // Phase 15 폴백 회귀 — LA alert 도달 불가면 같은 문구의 로컬 노티로 갈아탄다.
        let harness = makeHarness(isAppActive: false)
        await harness.primePreviousSession(departure: fixedNow.addingTimeInterval(3600))

        await harness.activity.setReachable(false)
        harness.evaluate.fix(.advanced(by: 600, actionable: true))
        harness.refresh.enqueue(.success(info(route: "r1", departure: fixedNow.addingTimeInterval(3000))))
        await harness.sut.syncNow()

        #expect(await harness.noti.posted.count == 1)
        #expect(await harness.activity.alertCount == 0)
    }

    @Test
    func advanced_foreground_quietUpdateOnly() async {
        // 포그라운드 — alert·노티 없이 조용한 갱신(배지)만. 주의는 인앱 채널 단독.
        let harness = makeHarness(isAppActive: true)
        await harness.primePreviousSession(departure: fixedNow.addingTimeInterval(3600))
        let updatesBefore = await harness.activity.updates.count

        harness.evaluate.fix(.advanced(by: 600, actionable: true))
        harness.refresh.enqueue(.success(info(route: "r1", departure: fixedNow.addingTimeInterval(3000))))
        await harness.sut.syncNow()

        #expect(await harness.activity.alertCount == 0)
        #expect(await harness.noti.posted.isEmpty)
        #expect(await harness.activity.updates.count == updatesBefore + 1)
    }

    // MARK: - 최후통첩 (새 알람 시각이 이미 과거·출발은 미래)

    @Test
    func ultimatum_foreground_staysQuiet_backgroundEscalates() async {
        // Phase 15 이중 알림 제거 회귀: 포그라운드 최후통첩은 조용한 상태 갱신뿐이다.
        let harness = makeHarness(isAppActive: true)
        await harness.primePreviousSession(departure: fixedNow.addingTimeInterval(3600))

        harness.evaluate.fix(.advanced(by: 3500, actionable: true))
        // 출발 100초 뒤 → 알람 시각(출발−180초)은 이미 과거 = 마지노선 침범.
        let ultimatumInfo = info(route: "r1", departure: fixedNow.addingTimeInterval(100))
        harness.refresh.enqueue(.success(ultimatumInfo))
        await harness.sut.syncNow()

        #expect(await harness.activity.alertCount == 0)
        #expect(await harness.noti.posted.isEmpty)
        let lastQuiet = await harness.activity.updates.last
        #expect(lastQuiet?.state.urgency == .imminent)

        // 백그라운드 + 도달 불가 — 즉시 최후통첩이 로컬 노티로 나간다.
        harness.active.set(false)
        await harness.activity.setReachable(false)
        harness.refresh.enqueue(.success(ultimatumInfo))
        await harness.sut.syncNow()

        #expect(await harness.noti.posted.count == 1)
    }

    // MARK: - missed (advanced, actionable: false)

    @Test
    func missed_background_unreachable_fallsBackToLocalNotification() async {
        let harness = makeHarness(isAppActive: false)
        await harness.primePreviousSession(departure: fixedNow.addingTimeInterval(3600))

        await harness.activity.setReachable(false)
        harness.evaluate.fix(.advanced(by: 3700, actionable: false))
        harness.refresh.enqueue(.success(info(route: "r1", departure: fixedNow.addingTimeInterval(-100))))
        await harness.sut.syncNow()

        #expect(await harness.noti.posted.count == 1)
        // 실패 상태 전환은 LA 종료가 아니라 missed 상태 업데이트다 — end 호출 없음.
        #expect(await harness.activity.finals.isEmpty)
    }

    // MARK: - sessionEnded

    @Test
    func sessionEnded_cancelsAlarmClearsSnapshotAndEndsActivity() async {
        let harness = makeHarness(isAppActive: false)
        await harness.primePreviousSession(departure: fixedNow.addingTimeInterval(3600))
        #expect(await harness.store.snapshot != nil)

        harness.evaluate.fix(.sessionEnded)
        harness.refresh.enqueue(.success(info(route: "r1", departure: nil)))
        await harness.sut.syncNow()

        #expect(await harness.scheduler.cancelCount == 1)
        #expect(await harness.store.snapshot == nil)
        #expect(await harness.activity.finals.last?.phase == .serviceEnded)
        #expect(await harness.noti.posted.isEmpty) // 종료는 행동을 요구하지 않는다 — 폴백 없음.
    }

    // MARK: - 클라 자체 만료 (Phase 13 회귀)

    @Test
    func localExpiry_refreshFailure_finalizesTombstoneAndCancelsAlarm() async {
        // 시딩된 과거 세션(출발+유예 경과) + refresh 실패 → 로컬 sessionEnded 확정.
        let pastDeparture = fixedNow.addingTimeInterval(-120)
        let harness = makeHarness(seeded: AlarmSessionSnapshot(
            info: info(route: "r1", departure: pastDeparture),
            firstWalkSeconds: nil,
            routeDisplayName: "",
            transportMode: nil,
            acknowledged: false,
            expired: false,
            syncedAt: fixedNow.addingTimeInterval(-3600)
        ))
        var changeIterator = harness.sut.changes().makeAsyncIterator()
        for _ in 0..<20 { await Task.yield() } // 구독 등록 드레인(변경 스트림은 replay 없음)

        await harness.sut.syncNow() // refresh 큐 비어 있음 → 실패여도 만료는 확정된다.

        #expect(await harness.scheduler.cancelCount == 1)
        #expect(await harness.store.snapshot?.expired == true)
        #expect(await harness.activity.finals.last?.phase == .serviceEnded)
        let verdict = await changeIterator.next()
        #expect(verdict == .sessionEnded)
    }

    @Test
    func localExpiry_serverReturnsFutureDeparture_serverWins() async {
        // 만료 후보 상태에서 refresh가 미래 출발을 주면 만료를 취소한다(서버 우선).
        let harness = makeHarness(seeded: AlarmSessionSnapshot(
            info: info(route: "r1", departure: fixedNow.addingTimeInterval(-120)),
            firstWalkSeconds: nil,
            routeDisplayName: "",
            transportMode: nil,
            acknowledged: false,
            expired: false
        ))
        let future = fixedNow.addingTimeInterval(1800)
        harness.refresh.enqueue(.success(info(route: "r1", departure: future)))

        await harness.sut.syncNow()

        #expect(await harness.scheduler.cancelCount == 0)
        #expect(await harness.store.snapshot?.expired == false)
        #expect(await harness.store.snapshot?.info.departureTime == future)
    }

    // MARK: - 수동 갱신 합류 (Phase 16)

    @Test
    func syncNow_joinsInFlightSync() async {
        // 당김·포그라운드 복귀가 겹쳐도 refresh는 1회 — inFlight 합류 회귀.
        let harness = makeHarness()
        harness.refresh.enqueue(.success(info(route: "r1", departure: fixedNow.addingTimeInterval(3600))))
        // 큐에 1건뿐 — 두 번째 실호출이 발생하면 실패(StubError)로 lastInfo가 남지 않는다.

        async let first: Void = harness.sut.syncNow()
        async let second: Void = harness.sut.syncNow()
        _ = await (first, second)

        var iterator = harness.sut.updates().makeAsyncIterator()
        let replayed = await iterator.next()
        #expect(replayed?.info.lastRouteId == "r1")
    }
}
