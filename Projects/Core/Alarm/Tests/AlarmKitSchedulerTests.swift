import AppIntents
@testable import CoreAlarm
import Foundation
import Synchronization
import Testing

private struct StubError: Error {}

/// stopIntent 주입 검증용 대역 — perform은 테스트에서 호출되지 않는다.
private struct StubStopIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "stub"
    func perform() async throws -> some IntentResult { .result() }
}

/// AlarmKit 대역 — 호출 순서와 시스템에 남아 있는 알람 ID 집합을 흉내 낸다.
private actor SpyEngine: AlarmEngine {
    private(set) var events: [String] = []
    private var alarmIDsInSystem: [UUID]
    private let authorizationResult: Result<Bool, any Error>
    private let scheduleError: (any Error)?
    /// true면 stopIntent가 실린 schedule만 실패시킨다 — 인텐트 폴백 경로 검증용.
    private let failsOnlyWithIntent: Bool

    init(
        existingIDs: [UUID] = [],
        authorization: Result<Bool, any Error> = .success(true),
        scheduleError: (any Error)? = nil,
        failsOnlyWithIntent: Bool = false
    ) {
        self.alarmIDsInSystem = existingIDs
        self.authorizationResult = authorization
        self.scheduleError = scheduleError
        self.failsOnlyWithIntent = failsOnlyWithIntent
    }

    func requestAuthorization() async throws -> Bool {
        events.append("auth")
        return try authorizationResult.get()
    }

    func schedule(
        id: UUID, fireDate: Date, title: String, stopIntent: (any LiveActivityIntent)?
    ) async throws {
        events.append("schedule:\(title)\(stopIntent == nil ? "" : ":intent")")
        if failsOnlyWithIntent, stopIntent != nil { throw StubError() }
        if let scheduleError { throw scheduleError }
        alarmIDsInSystem.append(id)
    }

    func cancel(id: UUID) async {
        events.append("cancel")
        alarmIDsInSystem.removeAll { $0 == id }
    }

    func alarmIDs() async -> [UUID] {
        alarmIDsInSystem
    }

    /// 발화·삭제 등으로 시스템에서 알람이 사라진 상황을 흉내 낸다.
    func removeAllFromSystem() {
        alarmIDsInSystem.removeAll()
    }
}

private final class InMemoryRecordStore: AlarmRecordStoring, Sendable {
    private let record = Mutex<ScheduledAlarmRecord?>(nil)

    func load() -> ScheduledAlarmRecord? { record.withLock { $0 } }
    func save(_ new: ScheduledAlarmRecord) { record.withLock { $0 = new } }
    func clear() { record.withLock { $0 = nil } }
}

private func makeSpec(id: String = "route-1") -> AlarmSpec {
    AlarmSpec(id: id, fireDate: Date(timeIntervalSince1970: 1_000), title: "막차 출발 알림")
}

struct AlarmKitSchedulerTests {
    @Test
    func replaceAlarm_existingAlarms_cancelsAllBeforeScheduling() async throws {
        let engine = SpyEngine(existingIDs: [UUID(), UUID()])
        let sut = AlarmKitScheduler(engine: engine, recordStore: InMemoryRecordStore())

        try await sut.replaceAlarm(makeSpec())

        #expect(await engine.events == ["cancel", "cancel", "schedule:막차 출발 알림"])
    }

    @Test
    func replaceAlarm_scheduleFails_throwsAndKeepsNoRecord() async {
        let engine = SpyEngine(scheduleError: StubError())
        let store = InMemoryRecordStore()
        let sut = AlarmKitScheduler(engine: engine, recordStore: store)

        await #expect(throws: StubError.self) {
            try await sut.replaceAlarm(makeSpec())
        }
        #expect(store.load() == nil)
        #expect(await sut.scheduledAlarm() == nil)
    }

    @Test
    func scheduledAlarm_afterReplace_returnsSpec() async throws {
        let sut = AlarmKitScheduler(engine: SpyEngine(), recordStore: InMemoryRecordStore())

        try await sut.replaceAlarm(makeSpec(id: "route-9"))

        #expect(await sut.scheduledAlarm() == makeSpec(id: "route-9"))
    }

    @Test
    func scheduledAlarm_afterCancelAll_returnsNil() async throws {
        let store = InMemoryRecordStore()
        let sut = AlarmKitScheduler(engine: SpyEngine(), recordStore: store)

        try await sut.replaceAlarm(makeSpec())
        await sut.cancelAll()

        #expect(await sut.scheduledAlarm() == nil)
        #expect(store.load() == nil)
    }

    @Test
    func scheduledAlarm_alarmGoneFromSystem_returnsNilAndClearsRecord() async throws {
        let engine = SpyEngine()
        let store = InMemoryRecordStore()
        let sut = AlarmKitScheduler(engine: engine, recordStore: store)

        try await sut.replaceAlarm(makeSpec())
        await engine.removeAllFromSystem()

        #expect(await sut.scheduledAlarm() == nil)
        #expect(store.load() == nil)
    }

    // MARK: - stopIntent (Phase 13)

    @Test
    func replaceAlarm_withStopIntent_schedulesIntentCarryingAlarm() async throws {
        let engine = SpyEngine()
        let sut = AlarmKitScheduler(
            engine: engine, recordStore: InMemoryRecordStore(), stopIntent: StubStopIntent()
        )

        try await sut.replaceAlarm(makeSpec())

        #expect(await engine.events == ["schedule:막차 출발 알림:intent"])
        #expect(await sut.scheduledAlarm() == makeSpec())
    }

    @Test
    func replaceAlarm_intentScheduleFails_retriesWithoutIntent() async throws {
        // 회귀 금지 계약: 인텐트 주입 실패가 알람 등록을 실패시키면 안 된다.
        let engine = SpyEngine(failsOnlyWithIntent: true)
        let store = InMemoryRecordStore()
        let sut = AlarmKitScheduler(
            engine: engine, recordStore: store, stopIntent: StubStopIntent()
        )

        try await sut.replaceAlarm(makeSpec())

        #expect(await engine.events == ["schedule:막차 출발 알림:intent", "schedule:막차 출발 알림"])
        #expect(store.load() != nil)
        #expect(await sut.scheduledAlarm() == makeSpec())
    }

    @Test
    func replaceAlarm_bothAttemptsFail_throwsAndKeepsNoRecord() async {
        let engine = SpyEngine(scheduleError: StubError())
        let store = InMemoryRecordStore()
        let sut = AlarmKitScheduler(
            engine: engine, recordStore: store, stopIntent: StubStopIntent()
        )

        await #expect(throws: StubError.self) {
            try await sut.replaceAlarm(makeSpec())
        }
        #expect(store.load() == nil)
    }

    @Test
    func requestAuthorization_granted_returnsTrue() async {
        let sut = AlarmKitScheduler(
            engine: SpyEngine(authorization: .success(true)),
            recordStore: InMemoryRecordStore()
        )
        #expect(await sut.requestAuthorization())
    }

    @Test
    func requestAuthorization_denied_returnsFalse() async {
        let sut = AlarmKitScheduler(
            engine: SpyEngine(authorization: .success(false)),
            recordStore: InMemoryRecordStore()
        )
        #expect(await sut.requestAuthorization() == false)
    }

    @Test
    func requestAuthorization_engineThrows_returnsFalse() async {
        let sut = AlarmKitScheduler(
            engine: SpyEngine(authorization: .failure(StubError())),
            recordStore: InMemoryRecordStore()
        )
        #expect(await sut.requestAuthorization() == false)
    }
}
