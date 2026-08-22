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
    var existing: AlarmInfo? = nil
    var registerError: Error? = nil

    func register(lastRouteId: String) async throws {
        await log.append("register:\(lastRouteId)")
        if let registerError { throw registerError }
    }

    func cancel(lastRouteId: String) async throws {
        await log.append("cancel:\(lastRouteId)")
    }

    func refresh() async throws -> AlarmInfo {
        await log.append("refresh")
        guard let existing else { throw StubError() }
        return existing
    }
}

private struct SpyAlarmScheduler: AlarmScheduler {
    let log: CallLog

    func replaceAlarm(id: String, fireDate: Date, title: String) async throws {
        await log.append("replaceAlarm:\(id)")
    }

    func cancelAlarm() async {
        await log.append("cancelAlarm")
    }
}

private extension LastRoute {
    static func fixture(id: String) -> LastRoute {
        LastRoute(
            id: id,
            departureTime: Date(timeIntervalSince1970: 1_000),
            totalTime: 0,
            totalWalkTime: 0,
            transferCount: 0,
            totalDistance: 0,
            totalWalkDistance: 0,
            legs: []
        )
    }
}

struct DefaultRegisterAlarmUseCaseTests {
    @Test
    func execute_existingAlarm_cancelsThenRegistersThenSchedules() async throws {
        let log = CallLog()
        let existing = AlarmInfo(lastRouteId: "old", departureTime: nil, updatedAt: nil, isReal: false)
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log, existing: existing),
            scheduler: SpyAlarmScheduler(log: log)
        )
        try await sut.execute(route: .fixture(id: "new"))
        #expect(await log.events == ["refresh", "cancel:old", "register:new", "replaceAlarm:new"])
    }

    @Test
    func execute_noExistingAlarm_skipsCancel() async throws {
        let log = CallLog()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log)
        )
        try await sut.execute(route: .fixture(id: "new"))
        #expect(await log.events == ["refresh", "register:new", "replaceAlarm:new"])
    }

    @Test
    func execute_serverRegisterFails_doesNotSchedule() async {
        let log = CallLog()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log, registerError: StubError()),
            scheduler: SpyAlarmScheduler(log: log)
        )
        await #expect(throws: StubError.self) {
            try await sut.execute(route: .fixture(id: "new"))
        }
        #expect(await log.events == ["refresh", "register:new"])
    }
}
