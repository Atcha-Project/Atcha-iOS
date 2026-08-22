@testable import Domain
import Foundation
import Testing

private actor CallLog {
    private(set) var events: [String] = []
    func append(_ event: String) { events.append(event) }
}

private struct StubError: Error {}

private struct StubAlarmRepository: AlarmRepository {
    let log: CallLog
    var refreshResult: Result<AlarmInfo, any Error>

    func register(lastRouteId: String) async throws {
        await log.append("register:\(lastRouteId)")
    }

    func cancel(lastRouteId: String) async throws {
        await log.append("cancel:\(lastRouteId)")
    }

    func refresh() async throws -> AlarmInfo {
        await log.append("refresh")
        return try refreshResult.get()
    }
}

private struct SpyAlarmScheduler: AlarmScheduler {
    let log: CallLog
    var scheduledDate: Date? = nil

    func requestAuthorization() async -> Bool { true }

    func replaceAlarm(id: String, fireDate: Date, title: String) async throws {
        await log.append("replaceAlarm:\(id)@\(Int(fireDate.timeIntervalSince1970))")
    }

    func cancelAlarm() async {
        await log.append("cancelAlarm")
    }

    func scheduledFireDate() async -> Date? {
        await log.append("scheduledFireDate")
        return scheduledDate
    }
}

private func makeInfo(departureTime: Date?) -> AlarmInfo {
    AlarmInfo(lastRouteId: "route-1", departureTime: departureTime, updatedAt: nil, isReal: true)
}

struct DefaultRefreshAlarmUseCaseTests {
    @Test
    func execute_departureChanged_reschedules() async throws {
        let log = CallLog()
        let newDeparture = Date(timeIntervalSince1970: 2_000)
        let sut = DefaultRefreshAlarmUseCase(
            repository: StubAlarmRepository(log: log, refreshResult: .success(makeInfo(departureTime: newDeparture))),
            scheduler: SpyAlarmScheduler(log: log, scheduledDate: Date(timeIntervalSince1970: 1_000))
        )
        let info = try await sut.execute()
        #expect(info.departureTime == newDeparture)
        #expect(await log.events == ["refresh", "scheduledFireDate", "replaceAlarm:route-1@2000"])
    }

    @Test
    func execute_departureUnchanged_doesNotReschedule() async throws {
        let log = CallLog()
        let departure = Date(timeIntervalSince1970: 1_000)
        let sut = DefaultRefreshAlarmUseCase(
            repository: StubAlarmRepository(log: log, refreshResult: .success(makeInfo(departureTime: departure))),
            scheduler: SpyAlarmScheduler(log: log, scheduledDate: departure)
        )
        _ = try await sut.execute()
        #expect(await log.events == ["refresh", "scheduledFireDate"])
    }

    @Test
    func execute_localAlarmMissing_reschedules() async throws {
        let log = CallLog()
        let departure = Date(timeIntervalSince1970: 3_000)
        let sut = DefaultRefreshAlarmUseCase(
            repository: StubAlarmRepository(log: log, refreshResult: .success(makeInfo(departureTime: departure))),
            scheduler: SpyAlarmScheduler(log: log, scheduledDate: nil)
        )
        _ = try await sut.execute()
        #expect(await log.events == ["refresh", "scheduledFireDate", "replaceAlarm:route-1@3000"])
    }

    @Test
    func execute_noDepartureTime_doesNotTouchScheduler() async throws {
        let log = CallLog()
        let sut = DefaultRefreshAlarmUseCase(
            repository: StubAlarmRepository(log: log, refreshResult: .success(makeInfo(departureTime: nil))),
            scheduler: SpyAlarmScheduler(log: log)
        )
        _ = try await sut.execute()
        #expect(await log.events == ["refresh"])
    }

    @Test
    func execute_refreshFails_throwsWithoutScheduling() async {
        let log = CallLog()
        let sut = DefaultRefreshAlarmUseCase(
            repository: StubAlarmRepository(log: log, refreshResult: .failure(StubError())),
            scheduler: SpyAlarmScheduler(log: log)
        )
        await #expect(throws: StubError.self) {
            _ = try await sut.execute()
        }
        #expect(await log.events == ["refresh"])
    }
}
