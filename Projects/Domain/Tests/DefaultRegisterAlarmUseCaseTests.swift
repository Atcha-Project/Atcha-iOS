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
        await log.append("replaceAlarm:\(id)@\(Int(fireDate.timeIntervalSince1970))")
    }

    func cancelAlarm() async {
        await log.append("cancelAlarm")
    }

    func scheduledFireDate() async -> Date? { nil }
}

private actor SpySnapshotStore: AlarmSessionSnapshotStore {
    private(set) var saved: [AlarmSessionSnapshot] = []
    private(set) var clearCount = 0
    var stored: AlarmSessionSnapshot?

    func load() async -> AlarmSessionSnapshot? { stored }

    func save(_ snapshot: AlarmSessionSnapshot) async {
        saved.append(snapshot)
        stored = snapshot
    }

    func clear() async {
        clearCount += 1
        stored = nil
    }
}

private extension LastRoute {
    static func fixture(id: String, legs: [TransportLeg] = []) -> LastRoute {
        LastRoute(
            id: id,
            departureTime: Date(timeIntervalSince1970: 1_000),
            totalTime: 0,
            totalWalkTime: 0,
            transferCount: 0,
            totalDistance: 0,
            totalWalkDistance: 0,
            legs: legs
        )
    }
}

private func walkLeg(sectionTime: Int) -> TransportLeg {
    TransportLeg(
        mode: .walk, sectionTime: sectionTime, distance: 100, departureTime: nil,
        routeName: nil, lineType: nil, start: nil, end: nil,
        subwayFinalStation: nil, subwayDirection: nil,
        isExpressSubway: false, isLastSubway: false
    )
}

private func busLeg(routeName: String) -> TransportLeg {
    TransportLeg(
        mode: .bus, sectionTime: 900, distance: 4_000, departureTime: nil,
        routeName: routeName, lineType: "11", start: nil, end: nil,
        subwayFinalStation: nil, subwayDirection: nil,
        isExpressSubway: false, isLastSubway: false
    )
}

/// 픽스처가 1970 부근의 작은 epoch를 쓰므로, tooLate 사전 가드(발화 시각 > now)를
/// 통과시키려면 now도 그보다 이른 고정값으로 주입한다.
private let fixedNow: @Sendable () -> Date = { Date(timeIntervalSince1970: 0) }

struct DefaultRegisterAlarmUseCaseTests {
    @Test
    func execute_existingAlarm_cancelsThenRegistersThenSchedules() async throws {
        let log = CallLog()
        let existing = AlarmInfo(lastRouteId: "old", departureTime: nil, updatedAt: nil, isReal: false)
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log, existing: existing),
            scheduler: SpyAlarmScheduler(log: log),
            now: fixedNow
        )
        try await sut.execute(route: .fixture(id: "new"))
        // 스케줄 시각은 버퍼 반영값: 출발 1000 − 180 = 820
        #expect(await log.events == ["auth:true", "refresh", "cancel:old", "register:new", "replaceAlarm:new@820"])
    }

    @Test
    func execute_noExistingAlarm_skipsCancel() async throws {
        let log = CallLog()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log),
            now: fixedNow
        )
        try await sut.execute(route: .fixture(id: "new"))
        #expect(await log.events == ["auth:true", "refresh", "register:new", "replaceAlarm:new@820"])
    }

    @Test
    func execute_routeWithWalkLeg_schedulesWalkAwareFireDate() async throws {
        // Phase 14: 발화 시각 = 출발 − 첫 도보 − 버퍼 = 1000 − 120 − 180 = 700.
        let log = CallLog()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log),
            now: fixedNow
        )
        try await sut.execute(route: .fixture(id: "new", legs: [walkLeg(sectionTime: 120)]))
        #expect(await log.events == ["auth:true", "refresh", "register:new", "replaceAlarm:new@700"])
    }

    @Test
    func execute_serverRegisterFails_doesNotSchedule() async {
        let log = CallLog()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log, registerError: StubError()),
            scheduler: SpyAlarmScheduler(log: log),
            now: fixedNow
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
            scheduler: SpyAlarmScheduler(log: log, authorizationGranted: false),
            now: fixedNow
        )
        await #expect(throws: AlarmError.permissionDenied) {
            try await sut.execute(route: .fixture(id: "new"))
        }
        // 권한 거부 시 서버 등록·삭제·로컬 스케줄 어디에도 도달하면 안 된다.
        #expect(await log.events == ["auth:false"])
    }

    // MARK: - tooLate 사전 가드 (Phase 14)

    @Test
    func execute_fireDateAlreadyPast_throwsTooLateBeforeAnySideEffect() async {
        let log = CallLog()
        let store = SpySnapshotStore()
        // 발화 시각 820 ≤ now 820 — 경계 포함 과거로 본다.
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log),
            snapshotStore: store,
            now: { Date(timeIntervalSince1970: 820) }
        )
        await #expect(throws: AlarmError.tooLate) {
            try await sut.execute(route: .fixture(id: "new"))
        }
        // 권한 팝업·서버 등록·스케줄·스냅샷 어디에도 도달하지 않는다(사전 가드).
        #expect(await log.events == [])
        #expect(await store.saved.isEmpty)
    }

    @Test
    func execute_walkMakesFireDatePast_throwsTooLate() async {
        // 도보 반영으로 발화 시각(700)이 now(750)보다 과거가 되는 경우도 가드에 걸린다.
        let log = CallLog()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log),
            now: { Date(timeIntervalSince1970: 750) }
        )
        await #expect(throws: AlarmError.tooLate) {
            try await sut.execute(route: .fixture(id: "new", legs: [walkLeg(sectionTime: 120)]))
        }
        #expect(await log.events == [])
    }

    // MARK: - 세션 스냅샷 (Phase 14)

    @Test
    func execute_success_savesSnapshotWithRouteFacts() async throws {
        let log = CallLog()
        let store = SpySnapshotStore()
        let route = LastRoute.fixture(
            id: "new", legs: [walkLeg(sectionTime: 120), busLeg(routeName: "간선:6411")]
        )
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log),
            snapshotStore: store,
            now: fixedNow
        )
        try await sut.execute(route: route)

        let saved = await store.saved
        #expect(saved.count == 1)
        #expect(saved.first?.info.lastRouteId == "new")
        #expect(saved.first?.info.departureTime == route.departureTime)
        #expect(saved.first?.firstWalkSeconds == 120)
        #expect(saved.first?.routeDisplayName == "6411번 버스")
        #expect(saved.first?.transportMode == .bus)
        #expect(saved.first?.acknowledged == false)
        #expect(saved.first?.expired == false)
    }

    @Test
    func execute_serverRegisterFails_doesNotSaveSnapshot() async {
        let log = CallLog()
        let store = SpySnapshotStore()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log, registerError: StubError()),
            scheduler: SpyAlarmScheduler(log: log),
            snapshotStore: store,
            now: fixedNow
        )
        await #expect(throws: StubError.self) {
            try await sut.execute(route: .fixture(id: "new"))
        }
        #expect(await store.saved.isEmpty)
    }
}
