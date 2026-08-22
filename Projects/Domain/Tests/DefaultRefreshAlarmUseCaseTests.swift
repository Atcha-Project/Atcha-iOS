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

/// 픽스처가 1970 부근의 작은 epoch를 쓰므로, "기대 발화 시각이 미래일 때만 재스케줄" 가드를
/// 통과시키려면 now도 그보다 이른 고정값으로 주입한다.
private let fixedNow: @Sendable () -> Date = { Date(timeIntervalSince1970: 0) }

struct DefaultRefreshAlarmUseCaseTests {
    @Test
    func execute_departureChanged_reschedules() async throws {
        let log = CallLog()
        let newDeparture = Date(timeIntervalSince1970: 2_000)
        let sut = DefaultRefreshAlarmUseCase(
            repository: StubAlarmRepository(log: log, refreshResult: .success(makeInfo(departureTime: newDeparture))),
            scheduler: SpyAlarmScheduler(log: log, scheduledDate: Date(timeIntervalSince1970: 1_000)),
            now: fixedNow
        )
        let info = try await sut.execute()
        #expect(info.departureTime == newDeparture)
        // 스케줄 시각은 버퍼 반영값: 2000 − 180 = 1820
        #expect(await log.events == ["refresh", "scheduledFireDate", "replaceAlarm:route-1@1820"])
    }

    @Test
    func execute_departureUnchanged_doesNotReschedule() async throws {
        let log = CallLog()
        let departure = Date(timeIntervalSince1970: 1_000)
        let sut = DefaultRefreshAlarmUseCase(
            repository: StubAlarmRepository(log: log, refreshResult: .success(makeInfo(departureTime: departure))),
            // 로컬 알람은 버퍼 반영값으로 스케줄돼 있으므로, 같은 기준으로 비교해야 헛재스케줄이 없다.
            scheduler: SpyAlarmScheduler(log: log, scheduledDate: AlarmTiming.alarmFireDate(departureTime: departure)),
            now: fixedNow
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
            scheduler: SpyAlarmScheduler(log: log, scheduledDate: nil),
            now: fixedNow
        )
        _ = try await sut.execute()
        // 스케줄 시각은 버퍼 반영값: 3000 − 180 = 2820
        #expect(await log.events == ["refresh", "scheduledFireDate", "replaceAlarm:route-1@2820"])
    }

    @Test
    func execute_expectedFireDateInPast_doesNotReschedule() async throws {
        let log = CallLog()
        // 기대 발화 시각(2000 − 180 = 1820)이 now(1900)보다 과거 — 재스케줄하면 AlarmKit이
        // 거부해 refresh 전체가 실패할 수 있다. 인지는 훅의 즉시 최후통첩 몫(정책 4).
        let sut = DefaultRefreshAlarmUseCase(
            repository: StubAlarmRepository(
                log: log,
                refreshResult: .success(makeInfo(departureTime: Date(timeIntervalSince1970: 2_000)))
            ),
            scheduler: SpyAlarmScheduler(log: log, scheduledDate: nil),
            now: { Date(timeIntervalSince1970: 1_900) }
        )
        _ = try await sut.execute()
        #expect(await log.events == ["refresh"])
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
