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
}
