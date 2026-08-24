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

private struct StubSnapshotStore: AlarmSessionSnapshotStore {
    let snapshot: AlarmSessionSnapshot?

    func load() async -> AlarmSessionSnapshot? { snapshot }
    func save(_ snapshot: AlarmSessionSnapshot) async {}
    func clear() async {}
}

private func makeSnapshot(routeId: String, firstWalkSeconds: Int?) -> AlarmSessionSnapshot {
    AlarmSessionSnapshot(
        info: AlarmInfo(lastRouteId: routeId, departureTime: nil, updatedAt: nil, isReal: true),
        firstWalkSeconds: firstWalkSeconds,
        routeDisplayName: "6411번 버스",
        transportMode: .bus,
        acknowledged: false,
        expired: false
    )
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
            scheduler: SpyAlarmScheduler(
                log: log,
                scheduledDate: AlarmTiming.alarmFireDate(
                    departureTime: departure, firstWalkSeconds: nil
                )
            ),
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

    // MARK: - 도보 반영 (Phase 14 — 스냅샷이 도보 초의 출처)

    @Test
    func execute_snapshotWalkSeconds_rescheduleUsesWalkAwareFireDate() async throws {
        let log = CallLog()
        let departure = Date(timeIntervalSince1970: 2_000)
        let sut = DefaultRefreshAlarmUseCase(
            repository: StubAlarmRepository(
                log: log, refreshResult: .success(makeInfo(departureTime: departure))
            ),
            scheduler: SpyAlarmScheduler(log: log, scheduledDate: nil),
            snapshotStore: StubSnapshotStore(
                snapshot: makeSnapshot(routeId: "route-1", firstWalkSeconds: 120)
            ),
            now: fixedNow
        )
        _ = try await sut.execute()
        // 기대 발화 시각 = 2000 − 120(도보) − 180(버퍼) = 1700 — 등록 경로와 같은 기준.
        #expect(await log.events == ["refresh", "scheduledFireDate", "replaceAlarm:route-1@1700"])
    }

    @Test
    func execute_snapshotWalkMatchingSchedule_doesNotReschedule() async throws {
        // 로컬 알람이 이미 도보 반영값으로 걸려 있으면 재스케줄하지 않는다(헛돎 금지).
        let log = CallLog()
        let departure = Date(timeIntervalSince1970: 2_000)
        let sut = DefaultRefreshAlarmUseCase(
            repository: StubAlarmRepository(
                log: log, refreshResult: .success(makeInfo(departureTime: departure))
            ),
            scheduler: SpyAlarmScheduler(
                log: log, scheduledDate: Date(timeIntervalSince1970: 1_700)
            ),
            snapshotStore: StubSnapshotStore(
                snapshot: makeSnapshot(routeId: "route-1", firstWalkSeconds: 120)
            ),
            now: fixedNow
        )
        _ = try await sut.execute()
        #expect(await log.events == ["refresh", "scheduledFireDate"])
    }

    @Test
    func execute_snapshotForDifferentRoute_ignoresItsWalkSeconds() async throws {
        // 서버가 다른 경로로 갈아탔으면 옛 경로의 도보 초는 무효 — 버퍼만 적용한다.
        let log = CallLog()
        let departure = Date(timeIntervalSince1970: 2_000)
        let sut = DefaultRefreshAlarmUseCase(
            repository: StubAlarmRepository(
                log: log, refreshResult: .success(makeInfo(departureTime: departure))
            ),
            scheduler: SpyAlarmScheduler(log: log, scheduledDate: nil),
            snapshotStore: StubSnapshotStore(
                snapshot: makeSnapshot(routeId: "other-route", firstWalkSeconds: 120)
            ),
            now: fixedNow
        )
        _ = try await sut.execute()
        #expect(await log.events == ["refresh", "scheduledFireDate", "replaceAlarm:route-1@1820"])
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
