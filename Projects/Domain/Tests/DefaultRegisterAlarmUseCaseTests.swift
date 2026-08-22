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
    var authorizationGranted = true

    func requestAuthorization() async -> Bool {
        await log.append("auth:\(authorizationGranted)")
        return authorizationGranted
    }

    func replaceAlarm(id: String, fireDate: Date, title: String) async throws {
        await log.append("replaceAlarm:\(id)")
    }

    func cancelAlarm() async {
        await log.append("cancelAlarm")
    }

    func scheduledFireDate() async -> Date? { nil }
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
        #expect(await log.events == ["auth:true", "refresh", "cancel:old", "register:new", "replaceAlarm:new"])
    }

    @Test
    func execute_noExistingAlarm_skipsCancel() async throws {
        let log = CallLog()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log)
        )
        try await sut.execute(route: .fixture(id: "new"))
        #expect(await log.events == ["auth:true", "refresh", "register:new", "replaceAlarm:new"])
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
        #expect(await log.events == ["auth:true", "refresh", "register:new"])
    }

    @Test
    func execute_permissionDenied_throwsAndHoldsServerRegistration() async {
        let log = CallLog()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log, authorizationGranted: false)
        )
        await #expect(throws: AlarmError.permissionDenied) {
            try await sut.execute(route: .fixture(id: "new"))
        }
        // 권한 거부 시 서버 등록·삭제·로컬 스케줄 어디에도 도달하면 안 된다.
        #expect(await log.events == ["auth:false"])
    }
}
