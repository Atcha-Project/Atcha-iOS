@testable import Domain
import Foundation
import Testing

private actor CallLog {
    private(set) var events: [String] = []
    func append(_ event: String) { events.append(event) }
}

private struct StubError: Error {}

private struct SpyAlarmRepository: AlarmRepository {
    let log: CallLog
    var cancelError: Error? = nil

    func register(lastRouteId: String) async throws {
        await log.append("register:\(lastRouteId)")
    }

    func cancel(lastRouteId: String) async throws {
        await log.append("cancel:\(lastRouteId)")
        if let cancelError { throw cancelError }
    }

    func refresh() async throws -> AlarmInfo {
        await log.append("refresh")
        throw StubError()
    }
}

private struct SpyAlarmScheduler: AlarmScheduler {
    let log: CallLog

    func requestAuthorization() async -> Bool { true }

    func replaceAlarm(id: String, fireDate: Date, title: String) async throws {
        await log.append("replaceAlarm:\(id)")
    }

    func cancelAlarm() async {
        await log.append("cancelAlarm")
    }

    func scheduledFireDate() async -> Date? { nil }
}

private actor SpySnapshotStore: AlarmSessionSnapshotStore {
    private(set) var clearCount = 0

    func load() async -> AlarmSessionSnapshot? { nil }
    func save(_ snapshot: AlarmSessionSnapshot) async {}
    func clear() async { clearCount += 1 }
}

struct DefaultCancelAlarmUseCaseTests {
    @Test
    func execute_serverCancelSucceeds_thenCancelsLocalAlarm() async throws {
        let log = CallLog()
        let sut = DefaultCancelAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log)
        )
        try await sut.execute(lastRouteId: "route-1")
        #expect(await log.events == ["cancel:route-1", "cancelAlarm"])
    }

    @Test
    func execute_serverCancelFails_keepsLocalAlarm() async {
        let log = CallLog()
        let sut = DefaultCancelAlarmUseCase(
            repository: SpyAlarmRepository(log: log, cancelError: StubError()),
            scheduler: SpyAlarmScheduler(log: log)
        )
        await #expect(throws: StubError.self) {
            try await sut.execute(lastRouteId: "route-1")
        }
        #expect(await log.events == ["cancel:route-1"])
    }

    // MARK: - 세션 스냅샷 (Phase 14)

    @Test
    func execute_success_clearsSnapshot() async throws {
        let log = CallLog()
        let store = SpySnapshotStore()
        let sut = DefaultCancelAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log),
            snapshotStore: store
        )
        try await sut.execute(lastRouteId: "route-1")
        #expect(await store.clearCount == 1)
    }

    @Test
    func execute_serverCancelFails_keepsSnapshot() async {
        // 세션은 아직 살아 있다 — 실패한 취소가 재실행 브리지를 지우면 안 된다.
        let log = CallLog()
        let store = SpySnapshotStore()
        let sut = DefaultCancelAlarmUseCase(
            repository: SpyAlarmRepository(log: log, cancelError: StubError()),
            scheduler: SpyAlarmScheduler(log: log),
            snapshotStore: store
        )
        await #expect(throws: StubError.self) {
            try await sut.execute(lastRouteId: "route-1")
        }
        #expect(await store.clearCount == 0)
    }
}
