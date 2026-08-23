@testable import Domain
import Foundation
import Testing

// LA 수명 정책 테스트 — 알람 등록 성공 → start, 알람 취소 → end.
// 기존 Default{Register,Cancel}AlarmUseCaseTests는 activityPort 없이(기본값 nil) 그대로 유효하다.

private actor CallLog {
    private(set) var events: [String] = []
    func append(_ event: String) { events.append(event) }
}

private actor SessionBox {
    private(set) var sessions: [AlarmInfo] = []
    private(set) var finals: [LastTrainActivityState] = []
    func capture(_ session: AlarmInfo) { sessions.append(session) }
    func capture(_ final: LastTrainActivityState) { finals.append(final) }
}

private struct StubError: Error {}

private struct SpyAlarmRepository: AlarmRepository {
    let log: CallLog
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
        throw StubError()
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

private struct SpyActivityPort: LastTrainActivityPort {
    let log: CallLog
    let box: SessionBox

    func start(session: AlarmInfo, route: LastRoute) async {
        await log.append("startLA:\(route.id)")
        await box.capture(session)
    }

    func update(state: LastTrainActivityState, alert: Bool) async {
        await log.append("updateLA")
    }

    func end(final: LastTrainActivityState) async {
        await log.append("endLA")
        await box.capture(final)
    }

    var isDismissedByUser: Bool { false }
}

private struct SpyLocalNotificationPort: LocalNotificationPort {
    let log: CallLog

    func requestAuthorizationIfNeeded() async {
        await log.append("requestNotiAuth")
    }

    func post(title: String, body: String) async {
        await log.append("postNoti:\(title)")
    }
}

/// 픽스처가 1970 부근의 작은 epoch를 쓰므로, tooLate 사전 가드(발화 시각 > now)를
/// 통과시키려면 now도 그보다 이른 고정값으로 주입한다.
private let fixedNow: @Sendable () -> Date = { Date(timeIntervalSince1970: 0) }

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

struct LastTrainActivityLifecycleTests {
    @Test
    func register_success_startsActivityOnceAfterLocalAlarm() async throws {
        let log = CallLog()
        let box = SessionBox()
        let route = LastRoute.fixture(id: "new")
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log),
            activityPort: SpyActivityPort(log: log, box: box),
            now: fixedNow
        )
        try await sut.execute(route: route)
        // 순서 계약: 알람(서버 등록 → 로컬 교체)이 항상 LA 시작에 선행한다.
        #expect(await log.events == ["auth:true", "refresh", "register:new", "replaceAlarm:new", "startLA:new"])
        // 세션은 route 기반으로 구성된다.
        let sessions = await box.sessions
        #expect(sessions.count == 1)
        #expect(sessions.first?.lastRouteId == "new")
        #expect(sessions.first?.departureTime == route.departureTime)
        #expect(sessions.first?.isReal == true)
    }

    @Test
    func register_serverFails_doesNotStartActivity() async {
        let log = CallLog()
        let box = SessionBox()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log, registerError: StubError()),
            scheduler: SpyAlarmScheduler(log: log),
            activityPort: SpyActivityPort(log: log, box: box),
            now: fixedNow
        )
        await #expect(throws: StubError.self) {
            try await sut.execute(route: .fixture(id: "new"))
        }
        // 알람 등록이 실패하면 LA는 시작되지 않는다.
        #expect(await log.events == ["auth:true", "refresh", "register:new"])
        #expect(await box.sessions.isEmpty)
    }

    @Test
    func register_permissionDenied_doesNotStartActivity() async {
        let log = CallLog()
        let box = SessionBox()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log, authorizationGranted: false),
            activityPort: SpyActivityPort(log: log, box: box),
            now: fixedNow
        )
        await #expect(throws: AlarmError.permissionDenied) {
            try await sut.execute(route: .fixture(id: "new"))
        }
        #expect(await log.events == ["auth:false"])
        #expect(await box.sessions.isEmpty)
    }

    @Test
    func register_success_requestsNotificationAuthOnceAfterActivityStart() async throws {
        let log = CallLog()
        let box = SessionBox()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log),
            activityPort: SpyActivityPort(log: log, box: box),
            notificationPort: SpyLocalNotificationPort(log: log),
            now: fixedNow
        )
        try await sut.execute(route: .fixture(id: "new"))
        // 순서 계약: 알림 권한 요청은 흐름의 맨 끝 — LA 시작 뒤에 정확히 1회.
        #expect(await log.events == [
            "auth:true", "refresh", "register:new", "replaceAlarm:new", "startLA:new", "requestNotiAuth",
        ])
    }

    @Test
    func register_serverFails_doesNotRequestNotificationAuth() async {
        let log = CallLog()
        let box = SessionBox()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log, registerError: StubError()),
            scheduler: SpyAlarmScheduler(log: log),
            activityPort: SpyActivityPort(log: log, box: box),
            notificationPort: SpyLocalNotificationPort(log: log),
            now: fixedNow
        )
        await #expect(throws: StubError.self) {
            try await sut.execute(route: .fixture(id: "new"))
        }
        // 서버 등록 실패 경로에서는 알림 권한을 요청하지 않는다.
        #expect(await log.events == ["auth:true", "refresh", "register:new"])
    }

    @Test
    func register_alarmKitPermissionDenied_doesNotRequestNotificationAuth() async {
        let log = CallLog()
        let box = SessionBox()
        let sut = DefaultRegisterAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log, authorizationGranted: false),
            activityPort: SpyActivityPort(log: log, box: box),
            notificationPort: SpyLocalNotificationPort(log: log),
            now: fixedNow
        )
        await #expect(throws: AlarmError.permissionDenied) {
            try await sut.execute(route: .fixture(id: "new"))
        }
        // AlarmKit 권한 거부 경로에서는 알림 권한을 요청하지 않는다(연속 팝업·스팸 금지).
        #expect(await log.events == ["auth:false"])
    }

    @Test
    func cancel_success_endsActivityAfterLocalCancel() async throws {
        let log = CallLog()
        let box = SessionBox()
        let sut = DefaultCancelAlarmUseCase(
            repository: SpyAlarmRepository(log: log),
            scheduler: SpyAlarmScheduler(log: log),
            activityPort: SpyActivityPort(log: log, box: box)
        )
        try await sut.execute(lastRouteId: "route-1")
        // 순서 계약: 서버 취소 → 로컬 알람 취소 → LA 종료.
        #expect(await log.events == ["cancel:route-1", "cancelAlarm", "endLA"])
        // 유저 취소는 실패 상태가 아니다 — phase .active로 종료한다.
        let finals = await box.finals
        #expect(finals.count == 1)
        #expect(finals.first?.phase == .active)
    }
}
