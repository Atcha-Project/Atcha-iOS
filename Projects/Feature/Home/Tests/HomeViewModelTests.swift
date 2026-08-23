import Domain
import Foundation
@testable import HomeFeature
import SearchFeatureInterface
import Testing

private struct StubError: Error {}

private struct StubGetCurrentLocationUseCase: GetCurrentLocationUseCase {
    let handler: @Sendable () async throws -> Coordinate
    func execute() async throws -> Coordinate { try await handler() }
}

private struct StubReverseGeocodeUseCase: ReverseGeocodeUseCase {
    let handler: @Sendable (Coordinate) async throws -> Place
    func execute(coordinate: Coordinate) async throws -> Place { try await handler(coordinate) }
}

private struct StubRegisterAlarmUseCase: RegisterAlarmUseCase {
    let handler: @Sendable (LastRoute) async throws -> Void
    /// 알림 권한 후속 신호(Phase 15) — 기본은 "요청·안내 없음".
    var authorizationOutcome: LocalNotificationAuthorizationOutcome = .alreadySettled

    @discardableResult
    func execute(route: LastRoute) async throws -> LocalNotificationAuthorizationOutcome {
        try await handler(route)
        return authorizationOutcome
    }
}

private struct StubCancelAlarmUseCase: CancelAlarmUseCase {
    let handler: @Sendable (String) async throws -> Void
    func execute(lastRouteId: String) async throws { try await handler(lastRouteId) }
}

private struct StubObserveAlarmUseCase: ObserveAlarmUseCase {
    let handler: @Sendable () -> AsyncStream<AlarmSyncUpdate>
    func execute() -> AsyncStream<AlarmSyncUpdate> { handler() }
}

private struct StubRequestAlarmSyncUseCase: RequestAlarmSyncUseCase {
    let handler: @Sendable () async -> Void
    func execute() async { await handler() }
}

private struct StubObserveAlarmChangeUseCase: ObserveAlarmChangeUseCase {
    let handler: @Sendable () -> AsyncStream<AlarmChangeVerdict>
    func execute() -> AsyncStream<AlarmChangeVerdict> { handler() }
}

private struct StubGetLastRouteDetailUseCase: GetLastRouteDetailUseCase {
    let handler: @Sendable (String) async throws -> LastRoute
    func execute(routeId: String) async throws -> LastRoute { try await handler(routeId) }
}

private struct StubSearchLastRoutesUseCase: SearchLastRoutesUseCase {
    let handler: @Sendable (Coordinate, Coordinate) async throws -> LastRouteSearchResult
    func execute(start: Coordinate, end: Coordinate) async throws -> LastRouteSearchResult {
        try await handler(start, end)
    }
}

private struct StubRecentSearchesUseCase: RecentSearchesUseCase {
    let fetchHandler: @Sendable () async throws -> [Place]
    let saveHandler: @Sendable (Place) async throws -> Void
    func fetch() async throws -> [Place] { try await fetchHandler() }
    func save(_ place: Place) async throws { try await saveHandler(place) }
    func remove(_ place: Place) async throws {}
}

/// 테스트 도중 스텁 동작을 바꾸거나 호출 횟수를 세기 위한 가변 박스 (NowBox와 동일 패턴).
private nonisolated final class ValueBox<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) { self.value = value }

    func get() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func update(_ transform: (Value) -> Value) {
        lock.lock()
        defer { lock.unlock() }
        value = transform(value)
    }
}

/// 테스트 도중 `now()`를 전진시키기 위한 가변 시계.
private nonisolated final class NowBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Date

    init(_ value: Date) { self.value = value }

    func get() -> Date {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func set(_ newValue: Date) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}

// MARK: - 헬퍼

@MainActor
private final class StateRecorder {
    private(set) var states: [HomeViewModel.State] = []
    private(set) var toasts: [HomeViewModel.ToastEvent] = []

    func attach(to sut: HomeViewModel) {
        sut.onStateChange = { [weak self] in self?.states.append($0) }
        sut.onToast = { [weak self] in self?.toasts.append($0) }
    }

    // 스텁이 즉시 resolve하므로 yield 드레인으로 충분하다.
    func waitUntilLast(_ predicate: (HomeViewModel.State) -> Bool) async {
        while !(states.last.map(predicate) ?? false) {
            await Task.yield()
        }
    }
}

private nonisolated let fixedNow = Date(timeIntervalSince1970: 1_755_800_000)

/// 검색 플로우가 동반하는 확정 도착지(Phase 17) — 도착지 필드 바인딩의 원천.
private nonisolated func makeArrival(_ name: String = "구로디지털단지역") -> Place {
    Place(
        name: name,
        address: "서울 구로구 도림천로 486",
        coordinate: Coordinate(latitude: 37.4853, longitude: 126.9015)
    )
}

private nonisolated func makeRoute(id: String, departure: Date) -> LastRoute {
    LastRoute(
        id: id,
        departureTime: departure,
        totalTime: 3600,
        totalWalkTime: 600,
        transferCount: 1,
        totalDistance: 12000,
        totalWalkDistance: 800,
        legs: [
            TransportLeg(
                mode: .subway,
                sectionTime: 1800,
                distance: 9000,
                departureTime: nil,
                routeName: "2호선",
                lineType: "2",
                start: RoutePoint(name: "강남역", coordinate: Coordinate(latitude: 37.49, longitude: 127.02)),
                end: RoutePoint(name: "당산역", coordinate: Coordinate(latitude: 37.53, longitude: 126.90)),
                subwayFinalStation: nil,
                subwayDirection: nil,
                isExpressSubway: false,
                isLastSubway: true
            ),
        ]
    )
}

@MainActor
private func makeSUT(
    location: @escaping @Sendable () async throws -> Coordinate = {
        Coordinate(latitude: 37.4979, longitude: 127.0276)
    },
    geocode: @escaping @Sendable (Coordinate) async throws -> Place = {
        Place(name: "강남역", address: "서울 강남구", coordinate: $0)
    },
    register: @escaping @Sendable (LastRoute) async throws -> Void = { _ in },
    registerOutcome: LocalNotificationAuthorizationOutcome = .alreadySettled,
    cancel: @escaping @Sendable (String) async throws -> Void = { _ in },
    alarmUpdates: @escaping @Sendable () -> AsyncStream<AlarmSyncUpdate> = {
        AsyncStream { $0.finish() }
    },
    alarmChanges: @escaping @Sendable () -> AsyncStream<AlarmChangeVerdict> = {
        AsyncStream { $0.finish() }
    },
    requestSync: @escaping @Sendable () async -> Void = {},
    routeDetail: @escaping @Sendable (String) async throws -> LastRoute = { _ in
        throw StubError()
    },
    searchRoutes: @escaping @Sendable (Coordinate, Coordinate) async throws -> LastRouteSearchResult = { _, _ in
        throw StubError()
    },
    recentFetch: @escaping @Sendable () async throws -> [Place] = { [] },
    recentSave: @escaping @Sendable (Place) async throws -> Void = { _ in },
    now: @escaping @Sendable () -> Date = { fixedNow },
    bannerTickInterval: Duration = .seconds(60)
) -> HomeViewModel {
    HomeViewModel(
        getCurrentLocationUseCase: StubGetCurrentLocationUseCase(handler: location),
        reverseGeocodeUseCase: StubReverseGeocodeUseCase(handler: geocode),
        registerAlarmUseCase: StubRegisterAlarmUseCase(
            handler: register, authorizationOutcome: registerOutcome
        ),
        cancelAlarmUseCase: StubCancelAlarmUseCase(handler: cancel),
        observeAlarmUseCase: StubObserveAlarmUseCase(handler: alarmUpdates),
        observeAlarmChangeUseCase: StubObserveAlarmChangeUseCase(handler: alarmChanges),
        requestAlarmSyncUseCase: StubRequestAlarmSyncUseCase(handler: requestSync),
        getLastRouteDetailUseCase: StubGetLastRouteDetailUseCase(handler: routeDetail),
        searchLastRoutesUseCase: StubSearchLastRoutesUseCase(handler: searchRoutes),
        recentSearchesUseCase: StubRecentSearchesUseCase(
            fetchHandler: recentFetch, saveHandler: recentSave
        ),
        now: now,
        bannerTickInterval: bannerTickInterval
    )
}

/// 스트림 yield용 축약 — 확인 시각이 무관한 기존 시나리오는 checkedAt 없이 흘린다.
private nonisolated func syncUpdate(
    _ info: AlarmInfo, checkedAt: Date? = nil
) -> AlarmSyncUpdate {
    AlarmSyncUpdate(info: info, checkedAt: checkedAt)
}

// MARK: - 테스트

@MainActor
struct HomeViewModelTests {
    @Test
    func viewDidLoad_locationSuccess_showsReverseGeocodedName() async {
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.departure == .current(name: "강남역") }

        // 초기값이 이미 .loading이라 didSet 재방출은 없다 — VC는 bind 시 초기 상태를 직접 렌더한다.
        #expect(sut.state.departure == .current(name: "강남역"))
        #expect(recorder.toasts.isEmpty)
    }

    @Test
    func viewDidLoad_permissionDenied_needsSearchAndEmitsSettingsToast() async {
        let sut = makeSUT(location: { throw LocationError.permissionDenied })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.departure == .needsSearch }

        #expect(recorder.toasts == [.locationPermissionNeeded])
    }

    @Test
    func viewDidLoad_otherFailure_needsSearchWithoutToast() async {
        let sut = makeSUT(geocode: { _ in throw StubError() })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.departure == .needsSearch }

        #expect(recorder.toasts.isEmpty)
    }

    // MARK: - 위치 권한 재확인 (Phase 15)

    @Test
    func didBecomeActive_needsSearch_recoversDepartureWithoutLoadingFlicker() async {
        // 최초 진입은 거부 → needsSearch. 설정에서 허용하고 돌아온(didBecomeActive) 상황.
        let granted = ValueBox(false)
        let sut = makeSUT(location: {
            guard granted.get() else { throw LocationError.permissionDenied }
            return Coordinate(latitude: 37.4979, longitude: 127.0276)
        })
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.departure == .needsSearch }
        let statesBefore = recorder.states.count

        granted.update { _ in true }
        sut.didBecomeActive()
        await recorder.waitUntilLast { $0.departure == .current(name: "강남역") }

        // 재확인 경로는 .loading을 거치지 않는다 — 성공 상태로만 전이(깜빡임 방지).
        #expect(!recorder.states.dropFirst(statesBefore).contains { $0.departure == .loading })
        // 거부 토스트는 최초 진입 1회뿐 — 재확인이 재발화하지 않는다.
        #expect(recorder.toasts == [.locationPermissionNeeded])
    }

    @Test
    func didBecomeActive_stillDenied_keepsStateAndEmitsNoToast() async {
        let calls = ValueBox(0)
        let sut = makeSUT(location: {
            calls.update { $0 + 1 }
            throw LocationError.permissionDenied
        })
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.departure == .needsSearch }
        let statesBefore = recorder.states.count

        sut.didBecomeActive()
        // 실패 경로는 상태 신호가 없다 — 재조회 호출을 확인한 뒤 후처리를 드레인한다.
        while calls.get() < 2 { await Task.yield() }
        for _ in 0..<20 { await Task.yield() }

        #expect(recorder.states.count == statesBefore)
        #expect(recorder.toasts == [.locationPermissionNeeded])
    }

    @Test
    func didBecomeActive_departureResolved_doesNotRequery() async {
        let calls = ValueBox(0)
        let sut = makeSUT(location: {
            calls.update { $0 + 1 }
            return Coordinate(latitude: 37.4979, longitude: 127.0276)
        })
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.departure == .current(name: "강남역") }

        // 권한 팝업 닫힘도 didBecomeActive를 울린다 — 이미 해결된 출발지는 재조회하지 않는다.
        sut.didBecomeActive()
        for _ in 0..<20 { await Task.yield() }

        #expect(calls.get() == 1)
    }

    @Test
    func routeSelected_populatesCard() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route, arrival: makeArrival())

        #expect(sut.state.routeCard == RouteCardViewData(entity: route, now: fixedNow))
        #expect(sut.state.banner == nil)
    }

    @Test
    func registerAlarm_success_startsBannerCountdown() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        #expect(sut.state.isAlarmBusy)
        await recorder.waitUntilLast { $0.banner != nil }

        // 카운트다운은 버퍼(3분) 포함 알람 발화 시각 기준 — 42분 출발이면 39분.
        #expect(sut.state.banner == .init(text: "출발까지 39분", urgency: .relaxed))
        #expect(!sut.state.isAlarmBusy)
        // 등록 성공 후 같은 자리 버튼이 해제로 토글된다.
        #expect(sut.state.alarmButton == .cancel)
    }

    // MARK: - 알림 권한 거부 1회 안내 (Phase 15)

    @Test
    func registerAlarm_notificationDeniedNow_emitsOneTimeGuidanceToast() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT(registerOutcome: .deniedNow)
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        while recorder.toasts.isEmpty { await Task.yield() }
        // 배너는 틱 태스크가 비동기로 채운다 — 토스트와 별도로 기다린다.
        await recorder.waitUntilLast { $0.banner != nil }

        // 등록 자체는 성공 — 배너·버튼은 정상 전이하고 안내 토스트만 덧붙는다.
        #expect(recorder.toasts == [.notificationPermissionDenied])
        #expect(sut.state.alarmButton == .cancel)
    }

    @Test
    func registerAlarm_notificationAlreadySettled_emitsNoGuidanceToast() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT(registerOutcome: .alreadySettled)
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil }

        #expect(recorder.toasts.isEmpty)
    }

    @Test
    func registerAlarm_failure_emitsToastAndKeepsBannerHidden() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT(register: { _ in throw StubError() })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        while recorder.toasts.isEmpty { await Task.yield() }

        #expect(recorder.toasts == [.alarmRegisterFailed])
        #expect(sut.state.banner == nil)
        #expect(!sut.state.isAlarmBusy)
        #expect(sut.state.alarmButton == .register)
    }

    @Test
    func selectingNewRoute_clearsExistingBanner() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil }

        sut.routeSelected(
            makeRoute(id: "r2", departure: fixedNow.addingTimeInterval(30 * 60)),
            arrival: makeArrival()
        )

        #expect(sut.state.banner == nil)
        #expect(sut.state.routeCard?.departureTimeText != nil)
    }

    @Test
    func minutesUntil_roundsUpAndClampsAtZero() {
        #expect(HomeViewModel.minutesUntil(
            departure: fixedNow.addingTimeInterval(42 * 60), now: fixedNow
        ) == 42)
        #expect(HomeViewModel.minutesUntil(
            departure: fixedNow.addingTimeInterval(90), now: fixedNow
        ) == 2)
        #expect(HomeViewModel.minutesUntil(
            departure: fixedNow.addingTimeInterval(-30), now: fixedNow
        ) == 0)
    }

    @Test
    func makeBanner_urgencyBoundaries_useAlarmFireDate() {
        // 카운트다운·긴급도 모두 알람 발화 시각(출발 − 3분 버퍼) 기준 — 이중 시각 금지.
        // 출발까지 13분 = 알람까지 정확히 600초: imminent 경계.
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(13 * 60), firstWalkSeconds: nil, now: fixedNow
        ) == .init(text: "출발까지 10분", urgency: .imminent))
        // 알람까지 601초: caution으로 넘어간다.
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(13 * 60 + 1), firstWalkSeconds: nil, now: fixedNow
        )?.urgency == .caution)
        // 출발까지 33분 = 알람까지 정확히 1800초: caution 경계.
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(33 * 60), firstWalkSeconds: nil, now: fixedNow
        ) == .init(text: "출발까지 30분", urgency: .caution))
        // 알람까지 1801초: relaxed.
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(33 * 60 + 1), firstWalkSeconds: nil, now: fixedNow
        )?.urgency == .relaxed)
    }

    @Test
    func makeBanner_threeStageTransition_boundaries() {
        // Phase 13: 1단계(카운트다운) → 2단계(지금 출발하세요) → 3단계(nil = 지난 막차).
        // 알람 직전(출발 3분 1초 전): 아직 1단계 — "출발까지 1분".
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(181), firstWalkSeconds: nil, now: fixedNow
        ) == .init(text: "출발까지 1분", urgency: .imminent))
        // 알람 시각 정각(출발 3분 전): 2단계 진입 — "출발까지 0분"은 존재하지 않는다.
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(180), firstWalkSeconds: nil, now: fixedNow
        ) == .init(text: "지금 출발하세요", urgency: .imminent))
        // 출발 정각·유예 마지막 초까지 2단계 유지.
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow, firstWalkSeconds: nil, now: fixedNow
        ) == .init(text: "지금 출발하세요", urgency: .imminent))
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(-59), firstWalkSeconds: nil, now: fixedNow
        ) == .init(text: "지금 출발하세요", urgency: .imminent))
        // 유예 경계(출발+60초)부터 3단계 — nil.
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(-60), firstWalkSeconds: nil, now: fixedNow
        ) == nil)
    }

    @Test
    func bannerTimer_graceElapsed_transitionsToPastTrainState() async {
        // 유예 경과 시 틱이 3단계 전이를 수행한다: 배너 제거 + "지난 막차" 카드(비활성 톤)
        // + 알람 버튼 숨김 + 틱 종료.
        let clock = NowBox(fixedNow)
        let departure = fixedNow.addingTimeInterval(42 * 60)
        let route = makeRoute(id: "r1", departure: departure)
        let sut = makeSUT(now: { clock.get() }, bannerTickInterval: .milliseconds(1))
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil }

        clock.set(departure.addingTimeInterval(60))
        await recorder.waitUntilLast { $0.banner == nil }

        #expect(sut.state.alarmButton == .hidden)
        #expect(sut.state.routeCard?.tone == .past)
        #expect(sut.state.routeCard?.badgeText == "지난 막차")
        #expect(sut.state.routeCard?.departureTimeText.hasSuffix("출발이었어요") == true)

        // 틱이 종료됐다 — 살아 있다면 1ms 틱이 상태를 계속 다시 쓴다.
        let stateCount = recorder.states.count
        try? await Task.sleep(for: .milliseconds(30))
        #expect(recorder.states.count == stateCount)
    }

    @Test
    func bannerTimer_ticksRecomputeMinutes() async {
        let clock = NowBox(fixedNow)
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT(now: { clock.get() }, bannerTickInterval: .milliseconds(1))
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner?.text == "출발까지 39분" }

        clock.set(fixedNow.addingTimeInterval(37 * 60))
        await recorder.waitUntilLast { $0.banner?.text == "출발까지 2분" }

        #expect(sut.state.banner?.urgency == .imminent)
    }

    @Test
    func registerAlarm_permissionDenied_emitsSettingsToast() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT(register: { _ in throw AlarmError.permissionDenied })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        while recorder.toasts.isEmpty { await Task.yield() }

        #expect(recorder.toasts == [.alarmPermissionNeeded])
        #expect(sut.state.banner == nil)
        #expect(!sut.state.isAlarmBusy)
        #expect(sut.state.alarmButton == .register)
    }

    @Test
    func cancelAlarm_success_hidesBannerAndTogglesButton() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil }

        sut.cancelAlarmTapped()
        await recorder.waitUntilLast { $0.banner == nil && !$0.isAlarmBusy }

        #expect(recorder.toasts.isEmpty)
        // 카드는 남아 있으므로 다시 등록할 수 있다.
        #expect(sut.state.alarmButton == .register)
        #expect(sut.state.routeCard != nil)
    }

    @Test
    func cancelAlarm_failure_emitsToastAndKeepsBanner() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT(cancel: { _ in throw StubError() })
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil }

        sut.cancelAlarmTapped()
        while recorder.toasts.isEmpty { await Task.yield() }

        #expect(recorder.toasts == [.alarmCancelFailed])
        #expect(sut.state.banner != nil)
        #expect(sut.state.alarmButton == .cancel)
    }

    @Test
    func alarmSync_restoresBannerAndCancelButtonWithoutCard() async {
        // 앱 재실행 복원 시나리오: 카드 없이 서버 알람만 있는 상태 — 앱 시작 동기화가
        // 스트림으로 도착한다.
        let departure = fixedNow.addingTimeInterval(30 * 60)
        let (stream, continuation) = AsyncStream<AlarmSyncUpdate>.makeStream()
        let sut = makeSUT(alarmUpdates: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        continuation.yield(syncUpdate(
            AlarmInfo(lastRouteId: "r1", departureTime: departure, updatedAt: nil, isReal: true)
        ))
        await recorder.waitUntilLast { $0.banner != nil }

        // 30분 출발 → 알람까지 27분(1620초) — caution 구간.
        #expect(sut.state.banner == .init(text: "출발까지 27분", urgency: .caution))
        #expect(sut.state.alarmButton == .cancel)
        #expect(sut.state.routeCard == nil)
    }

    @Test
    func alarmSync_updatesBannerToNewDeparture() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let (stream, continuation) = AsyncStream<AlarmSyncUpdate>.makeStream()
        let sut = makeSUT(alarmUpdates: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner?.text == "출발까지 39분" }

        // 서버가 15분 당긴 시각을 돌려준다 (포그라운드 복귀·푸시 동기화 공용 경로).
        continuation.yield(syncUpdate(
            AlarmInfo(
                lastRouteId: "r1",
                departureTime: fixedNow.addingTimeInterval(27 * 60),
                updatedAt: nil,
                isReal: true
            )
        ))
        await recorder.waitUntilLast { $0.banner?.text == "출발까지 24분" }

        #expect(sut.state.alarmButton == .cancel)
    }

    @Test
    func alarmSync_noEvent_keepsState() async {
        // 동기화 실패는 스트림에 흐르지 않는다 — 이벤트 없음 = 상태 유지.
        let sut = makeSUT(alarmUpdates: { AsyncStream { $0.finish() } })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        for _ in 0..<20 { await Task.yield() }

        #expect(sut.state.banner == nil)
        #expect(sut.state.alarmButton == .hidden)
        #expect(recorder.toasts.isEmpty)
    }

    @Test
    func changeStream_advancedActionable_emitsAdvancedToast() async {
        // 포그라운드 인앱 채널: 앞당겨짐(아직 탈 수 있음) → 원샷 토스트 이벤트.
        let (stream, continuation) = AsyncStream<AlarmChangeVerdict>.makeStream()
        let sut = makeSUT(alarmChanges: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        continuation.yield(.advanced(by: 15 * 60, actionable: true))
        while recorder.toasts.isEmpty { await Task.yield() }

        #expect(recorder.toasts == [.lastTrainAdvanced(minutes: 15)])
        // 배너 시각·긴급도 갱신은 info 스트림 몫 — verdict만으로 State는 바뀌지 않는다.
        #expect(sut.state.banner == nil)

        // 1분 미만 앞당김은 최소 1분으로 클램프한다.
        continuation.yield(.advanced(by: 20, actionable: true))
        while recorder.toasts.count < 2 { await Task.yield() }

        #expect(recorder.toasts == [
            .lastTrainAdvanced(minutes: 15),
            .lastTrainAdvanced(minutes: 1),
        ])
    }

    @Test
    func changeStream_quietVerdicts_emitNoToast() async {
        // 정책: 늦춰짐·변경 없음은 조용한 업데이트 — 배너는 info 스트림 몫, 토스트 없음.
        let (stream, continuation) = AsyncStream<AlarmChangeVerdict>.makeStream()
        let sut = makeSUT(alarmChanges: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        continuation.yield(.delayed(by: 10 * 60))
        continuation.yield(.unchanged)
        for _ in 0..<20 { await Task.yield() }

        #expect(recorder.toasts.isEmpty)
        #expect(sut.state.banner == nil)
    }

    @Test
    func changeStream_sessionEnded_clearsBannerResetsButtonAndToasts() async {
        // 운행 종료·경로 소멸: 배너 제거 + 등록 기록 삭제 + 버튼 리셋 + 원샷 안내.
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let (stream, continuation) = AsyncStream<AlarmChangeVerdict>.makeStream()
        let sut = makeSUT(alarmChanges: { stream }, bannerTickInterval: .milliseconds(1))
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil }

        continuation.yield(.sessionEnded)
        await recorder.waitUntilLast { $0.banner == nil }

        #expect(recorder.toasts == [.lastTrainServiceEnded])
        // 카드는 남고 등록 기록만 사라졌다 — 재등록 버튼으로 돌아간다.
        #expect(sut.state.alarmButton == .register)
        #expect(sut.state.routeCard != nil)

        // 배너 타이머도 멈췄다 — 살아 있다면 1ms 틱이 카운트다운을 곧장 되살린다.
        try? await Task.sleep(for: .milliseconds(30))
        #expect(sut.state.banner == nil)
    }

    @Test
    func changeStream_advancedNotActionable_freezesBannerAsMissedAndToasts() async {
        // 이미 못 타는 앞당김: 카운트다운 중지 + 배너 텍스트를 실패 문구로 교체(imminent 유지).
        let clock = NowBox(fixedNow)
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let (stream, continuation) = AsyncStream<AlarmChangeVerdict>.makeStream()
        let sut = makeSUT(
            alarmChanges: { stream },
            now: { clock.get() },
            bannerTickInterval: .milliseconds(1)
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner?.text == "출발까지 39분" }

        continuation.yield(.advanced(by: 5 * 60, actionable: false))
        await recorder.waitUntilLast { $0.banner?.text == "막차가 지나갔어요" }

        #expect(recorder.toasts == [.lastTrainMissed])
        #expect(sut.state.banner == .init(text: "막차가 지나갔어요", urgency: .imminent))
        // 등록 기록·버튼은 그대로 — 알람·서버 정리는 홈 밖(App·Domain) 몫이다.
        #expect(sut.state.alarmButton == .cancel)

        // 타이머가 살아 있다면 시계가 흐른 뒤 "출발까지 N분"으로 되돌린다 — 멈췄음을 확인.
        clock.set(fixedNow.addingTimeInterval(10 * 60))
        try? await Task.sleep(for: .milliseconds(30))
        #expect(sut.state.banner?.text == "막차가 지나갔어요")
    }

    @Test
    func alarmSync_pastGraceDeparture_doesNotStartCountdown() async {
        // 유예(출발+60초)가 지난 시각의 동기화 복원 — 지난 막차 배너를 되살리지 않는다.
        // 못 탐 판정이 고정한 실패 배너를 후속 동기화가 덮어쓰는 것도 같은 가드가 막는다.
        let (stream, continuation) = AsyncStream<AlarmSyncUpdate>.makeStream()
        let sut = makeSUT(alarmUpdates: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        continuation.yield(syncUpdate(
            AlarmInfo(
                lastRouteId: "r1",
                departureTime: fixedNow.addingTimeInterval(-60),
                updatedAt: nil,
                isReal: true
            )
        ))
        await recorder.waitUntilLast { $0.alarmButton == .cancel }

        #expect(sut.state.banner == nil)
    }

    @Test
    func alarmSync_withinGrace_restoresDepartNowBanner() async {
        // 발화~유예 창의 동기화 복원 — 2단계 "지금 출발하세요"도 복원 대상이다 (Phase 13).
        let (stream, continuation) = AsyncStream<AlarmSyncUpdate>.makeStream()
        let sut = makeSUT(alarmUpdates: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        continuation.yield(syncUpdate(
            AlarmInfo(
                lastRouteId: "r1",
                departureTime: fixedNow.addingTimeInterval(-30),
                updatedAt: nil,
                isReal: true
            )
        ))
        await recorder.waitUntilLast { $0.banner != nil }

        #expect(sut.state.banner == .init(text: "지금 출발하세요", urgency: .imminent))
        #expect(sut.state.alarmButton == .cancel)
    }

    @Test
    func makeBanner_acrossMidnight_usesAbsoluteDateArithmetic() {
        // 자정 경계: 23:40 → 익일 00:10 출발은 벽시계로는 "이른 시각"이지만 절대 시간으로는
        // 30분 뒤다 — 알람 발화 시각(00:07)까지 27분 카운트다운, caution.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 22, hour: 23, minute: 40)
        )!
        let departure = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 23, hour: 0, minute: 10)
        )!

        #expect(HomeViewModel.makeBanner(departure: departure, firstWalkSeconds: nil, now: now)
            == .init(text: "출발까지 27분", urgency: .caution))
    }

    // MARK: - 도보 시간 반영 (Phase 14)

    @Test
    func makeBanner_walkSeconds_shiftAlarmBase() {
        // 기준 = 출발 − 도보 − 버퍼: 출발 42분 뒤, 도보 120초면 알람까지 37분.
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(42 * 60), firstWalkSeconds: 120, now: fixedNow
        ) == .init(text: "출발까지 37분", urgency: .relaxed))
        // 도보 반영으로 알람 시각이 이미 지났으면(출발 5분 전, 도보 120초 → 알람 정각)
        // 2단계 "지금 출발하세요"에 진입한다.
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(5 * 60), firstWalkSeconds: 120, now: fixedNow
        ) == .init(text: "지금 출발하세요", urgency: .imminent))
    }

    @Test
    func registerAlarm_routeWithWalk_bannerUsesWalkAwareBase() async {
        // 등록 배너도 등록/LA와 같은 기준(출발 − 도보 − 버퍼)을 쓴다 — 이중 시각 금지.
        let route = makeWalkRoute(
            id: "r1", departure: fixedNow.addingTimeInterval(42 * 60), walkSeconds: 120
        )
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil }

        #expect(sut.state.banner == .init(text: "출발까지 37분", urgency: .relaxed))
    }

    // MARK: - tooLate 사전 가드 (Phase 14)

    @Test
    func registerAlarm_tooLate_emitsToastAndKeepsRegisterButton() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(60))
        let sut = makeSUT(register: { _ in throw AlarmError.tooLate })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        while recorder.toasts.isEmpty { await Task.yield() }

        #expect(recorder.toasts == [.alarmTooLate])
        #expect(sut.state.banner == nil)
        #expect(!sut.state.isAlarmBusy)
        #expect(sut.state.alarmButton == .register)
    }

    // MARK: - 변경 분 표기 올림 통일 (Phase 14)

    @Test
    func changeStream_advancedToast_roundsMinutesUp() async {
        // 61초 앞당김 → 올림 2분 — LA 잠금화면 문구(.up)와 같은 분으로 읽힌다.
        let (stream, continuation) = AsyncStream<AlarmChangeVerdict>.makeStream()
        let sut = makeSUT(alarmChanges: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        continuation.yield(.advanced(by: 61, actionable: true))
        while recorder.toasts.isEmpty { await Task.yield() }

        #expect(recorder.toasts == [.lastTrainAdvanced(minutes: 2)])
    }

    // MARK: - 재실행 카드 복원 (Phase 14)

    @Test
    func alarmSync_withoutCard_restoresCardFromRouteDetail() async {
        // 재실행 복원: 카드 없이 동기화가 도착하면 상세를 재조회해 카드·해제 버튼·
        // 도보 반영 배너까지 복원한다 — "무슨 경로인지 모르는 해제 버튼" 해소.
        let departure = fixedNow.addingTimeInterval(42 * 60)
        let route = makeWalkRoute(id: "r1", departure: departure, walkSeconds: 120)
        let (stream, continuation) = AsyncStream<AlarmSyncUpdate>.makeStream()
        let sut = makeSUT(
            alarmUpdates: { stream },
            routeDetail: { routeId in
                #expect(routeId == "r1")
                return route
            }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        continuation.yield(syncUpdate(
            AlarmInfo(lastRouteId: "r1", departureTime: departure, updatedAt: nil, isReal: true)
        ))
        await recorder.waitUntilLast { $0.routeCard != nil }

        #expect(sut.state.routeCard == RouteCardViewData(entity: route, now: fixedNow))
        #expect(sut.state.alarmButton == .cancel)
        // 배너도 상세의 도보 초 반영 기준으로 재시작됐다 (42분 − 2분 도보 − 3분 버퍼 = 37분).
        await recorder.waitUntilLast { $0.banner?.text == "출발까지 37분" }
    }

    @Test
    func alarmSync_detailFails_keepsCancelButtonWithoutCard() async {
        // 복원 실패는 현행 폴백 — 카드 없이 해제 버튼·배너만. (기본 routeDetail 스텁이 throw)
        let departure = fixedNow.addingTimeInterval(30 * 60)
        let (stream, continuation) = AsyncStream<AlarmSyncUpdate>.makeStream()
        let sut = makeSUT(alarmUpdates: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        continuation.yield(syncUpdate(
            AlarmInfo(lastRouteId: "r1", departureTime: departure, updatedAt: nil, isReal: true)
        ))
        await recorder.waitUntilLast { $0.banner != nil }
        for _ in 0..<20 { await Task.yield() }

        #expect(sut.state.routeCard == nil)
        #expect(sut.state.alarmButton == .cancel)
    }

    @Test
    func alarmSync_cardAlreadyVisible_doesNotFetchDetail() async {
        // 등록 직후의 동기화 — 카드가 이미 있으면 상세 재조회를 하지 않는다.
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let fetched = FetchFlag()
        let (stream, continuation) = AsyncStream<AlarmSyncUpdate>.makeStream()
        let sut = makeSUT(
            alarmUpdates: { stream },
            routeDetail: { _ in
                fetched.mark()
                throw StubError()
            }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil }

        continuation.yield(syncUpdate(
            AlarmInfo(
                lastRouteId: "r1",
                departureTime: fixedNow.addingTimeInterval(42 * 60),
                updatedAt: nil,
                isReal: true
            )
        ))
        for _ in 0..<20 { await Task.yield() }

        #expect(!fetched.value)
        #expect(sut.state.routeCard == RouteCardViewData(entity: route, now: fixedNow))
    }

    // MARK: - 수동 갱신 (Phase 16 pull-to-refresh)

    @Test
    func refreshPulled_invokesSyncAndSignalsFinish() async {
        let calls = ValueBox(0)
        let sut = makeSUT(requestSync: { calls.update { $0 + 1 } })
        let finished = ValueBox(0)
        sut.onManualSyncFinished = { finished.update { $0 + 1 } }

        sut.refreshPulled()
        while finished.get() < 1 { await Task.yield() }

        #expect(calls.get() == 1)
        #expect(finished.get() == 1)
    }

    @Test
    func refreshPulled_whileInFlight_isNoOp() async {
        // 스텁 동기화가 게이트에 막혀 있는 동안의 재당김은 no-op이어야 한다(이중 당김 무해).
        let gate = ValueBox(false)
        let calls = ValueBox(0)
        let sut = makeSUT(requestSync: {
            calls.update { $0 + 1 }
            while !gate.get() { await Task.yield() }
        })
        let finished = ValueBox(0)
        sut.onManualSyncFinished = { finished.update { $0 + 1 } }

        sut.refreshPulled()
        sut.refreshPulled()
        gate.update { _ in true }
        while finished.get() < 1 { await Task.yield() }
        for _ in 0..<20 { await Task.yield() }

        #expect(calls.get() == 1)
        #expect(finished.get() == 1)

        // 완료 후의 당김은 새 동기화다.
        sut.refreshPulled()
        while finished.get() < 2 { await Task.yield() }
        #expect(calls.get() == 2)
    }

    // MARK: - 신선도 스탬프 (Phase 16)

    @Test
    func freshnessText_requiresRegisteredSessionAndCheckedAt() {
        let checkedAt = fixedNow
        let expected = "\(makeStampFormatter().string(from: checkedAt)) 확인 기준"
        #expect(HomeViewModel.freshnessText(checkedAt: checkedAt, isRegistered: true) == expected)
        // 확인 시각이 없으면(구 스냅샷 시딩 등) 스탬프를 지어내지 않는다.
        #expect(HomeViewModel.freshnessText(checkedAt: nil, isRegistered: true) == nil)
        // 등록 세션이 없으면 후보 카드에 스탬프를 달지 않는다.
        #expect(HomeViewModel.freshnessText(checkedAt: checkedAt, isRegistered: false) == nil)
    }

    @Test
    func registerAlarm_success_stampsFreshnessWithNow() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route, arrival: makeArrival())
        #expect(sut.state.freshnessText == nil)
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil }

        // 등록 성공 = 서버 확인 — now(고정 시계) 기준으로 스탬프가 시작된다.
        #expect(sut.state.freshnessText
            == "\(makeStampFormatter().string(from: fixedNow)) 확인 기준")
    }

    @Test
    func alarmSync_checkedAt_updatesStamp_andSeededNilKeepsNoStamp() async {
        // 시딩 복원(checkedAt = 직전 확인 시각)은 그 낡은 시각을 그대로 표시하고,
        // 이후 성공 동기화(checkedAt = 새 시각)가 스탬프를 전진시킨다.
        let departure = fixedNow.addingTimeInterval(30 * 60)
        let seededCheckedAt = fixedNow.addingTimeInterval(-40 * 60)
        let (stream, continuation) = AsyncStream<AlarmSyncUpdate>.makeStream()
        let sut = makeSUT(alarmUpdates: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()

        continuation.yield(syncUpdate(
            AlarmInfo(lastRouteId: "r1", departureTime: departure, updatedAt: nil, isReal: true),
            checkedAt: seededCheckedAt
        ))
        await recorder.waitUntilLast { $0.freshnessText != nil }
        #expect(sut.state.freshnessText
            == "\(makeStampFormatter().string(from: seededCheckedAt)) 확인 기준")

        continuation.yield(syncUpdate(
            AlarmInfo(lastRouteId: "r1", departureTime: departure, updatedAt: nil, isReal: true),
            checkedAt: fixedNow
        ))
        await recorder.waitUntilLast {
            $0.freshnessText == "\(makeStampFormatter().string(from: fixedNow)) 확인 기준"
        }
    }

    @Test
    func manualSync_noStreamEvent_keepsStaleStamp() async {
        // 무음 실패의 표면: 당김이 아무 이벤트도 못 얻으면 스탬프는 낡은 시각을 유지한다.
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.freshnessText != nil }
        let stampBefore = sut.state.freshnessText

        let finished = ValueBox(0)
        sut.onManualSyncFinished = { finished.update { $0 + 1 } }
        sut.refreshPulled()
        while finished.get() < 1 { await Task.yield() }

        #expect(sut.state.freshnessText == stampBefore)
        #expect(recorder.toasts.isEmpty) // 실패 토스트 금지 — 무음 정책.
    }

    @Test
    func cancelAlarm_clearsFreshnessStamp() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.freshnessText != nil }

        sut.cancelAlarmTapped()
        await recorder.waitUntilLast { $0.banner == nil && !$0.isAlarmBusy }

        #expect(sut.state.freshnessText == nil)
    }

    // MARK: - 검색·홈 마찰 팩 (Phase 17)

    @Test
    func routeSelected_bindsArrivalFieldText() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT()

        #expect(sut.state.arrivalText == nil)
        sut.routeSelected(route, arrival: makeArrival("신림동"))

        #expect(sut.state.arrivalText == "신림동")
        // 새 경로 선택은 도착지명을 교체한다.
        sut.routeSelected(
            makeRoute(id: "r2", departure: fixedNow.addingTimeInterval(30 * 60)),
            arrival: makeArrival("당산역")
        )
        #expect(sut.state.arrivalText == "당산역")
    }

    @Test
    func searchFieldTapped_forwardsTappedFieldAsEntry() async {
        let sut = makeSUT()
        let received = ValueBox<[SearchEntryField]>([])
        sut.onSearchRequested = { field, _ in received.update { $0 + [field] } }

        sut.searchFieldTapped(.arrival)
        sut.searchFieldTapped(.departure)

        #expect(received.get() == [.arrival, .departure])
    }

    @Test
    func searchReply_bindsRouteCardAndArrival() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let arrival = makeArrival("신림동")
        let sut = makeSUT()
        sut.onSearchRequested = { _, reply in reply(route, arrival) }

        sut.searchFieldTapped(.arrival)

        #expect(sut.state.routeCard == RouteCardViewData(entity: route, now: fixedNow))
        #expect(sut.state.arrivalText == "신림동")
    }

    @Test
    func viewDidLoad_servicesDisabled_needsSearchAndEmitsSystemToast() async {
        let sut = makeSUT(location: { throw LocationError.servicesDisabled })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.departure == .needsSearch }
        while recorder.toasts.isEmpty { await Task.yield() }

        #expect(recorder.toasts == [.locationServicesDisabled])
    }

    @Test
    func viewDidLoad_restricted_needsSearchAndEmitsRestrictedToast() async {
        // restricted는 설정으로 못 푸는 제약 — 별도 안내(설정 이동 없음, VC 매핑)로 분기한다.
        let sut = makeSUT(location: { throw LocationError.restricted })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.departure == .needsSearch }
        while recorder.toasts.isEmpty { await Task.yield() }

        #expect(recorder.toasts == [.locationRestricted])
    }

    @Test
    func viewDidLoad_locationUnavailable_needsSearchWithoutToast() async {
        let sut = makeSUT(location: { throw LocationError.unavailable })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.departure == .needsSearch }
        for _ in 0..<20 { await Task.yield() }

        #expect(recorder.toasts.isEmpty)
    }

    @Test
    func routeCardViewData_labelsTomorrowDepartureAndArrival() {
        // 자정 넘김 표기 — 내일 출발 경로는 출발·도착 모두 "내일" 접두가 붙는다.
        let tomorrowDeparture = Calendar.current.date(byAdding: .day, value: 1, to: fixedNow)!
        let card = RouteCardViewData(
            entity: makeRoute(id: "r1", departure: tomorrowDeparture), now: fixedNow
        )
        #expect(card.departureTimeText.hasPrefix("내일 "))
        #expect(card.destinationText.hasPrefix("도착 내일 "))

        // 오늘 경로는 무라벨 — 무라벨 = 오늘.
        let today = RouteCardViewData(
            entity: makeRoute(id: "r2", departure: fixedNow.addingTimeInterval(3600)), now: fixedNow
        )
        #expect(!today.departureTimeText.hasPrefix("내일 "))
        #expect(!today.destinationText.contains("내일"))

        // "지난 막차" 카드는 라벨 스코프 밖 — 기존 문구 유지.
        let past = card.asPastTrain(departure: tomorrowDeparture)
        #expect(past.departureTimeText.hasSuffix("출발이었어요"))
        #expect(!past.departureTimeText.hasPrefix("내일 "))
    }

    @Test
    func sessionEndedAndExpiry_clearFreshnessStamp() async {
        // 종료·만료 정리와 함께 스탬프도 사라진다 — "지난 막차"에 신선도는 무의미하다.
        let clock = NowBox(fixedNow)
        let departure = fixedNow.addingTimeInterval(42 * 60)
        let route = makeRoute(id: "r1", departure: departure)
        let (stream, continuation) = AsyncStream<AlarmChangeVerdict>.makeStream()
        let sut = makeSUT(
            alarmChanges: { stream },
            now: { clock.get() },
            bannerTickInterval: .milliseconds(1)
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        sut.routeSelected(route, arrival: makeArrival())
        sut.registerAlarmTapped()
        // 스탬프는 배너보다 먼저 설정된다 — 배너까지 뜬 뒤에 종료를 흘려야 정리를 검증한다.
        await recorder.waitUntilLast { $0.banner != nil && $0.freshnessText != nil }

        continuation.yield(.sessionEnded)
        await recorder.waitUntilLast { $0.banner == nil }
        #expect(sut.state.freshnessText == nil)

        // 재등록 후 유예 경과(3단계 전이)도 스탬프를 정리한다.
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil && $0.freshnessText != nil }
        clock.set(departure.addingTimeInterval(60))
        await recorder.waitUntilLast { $0.banner == nil && $0.freshnessText == nil }
        #expect(sut.state.routeCard?.tone == .past)
    }

    // MARK: - 최근 경로 원탭 칩 (Phase 18)

    @Test
    func viewDidLoad_recentSearchExists_showsChipForLatest() async {
        // 칩은 최근 검색 최신 1건 — 목록의 첫 항목만 표면화한다.
        let sut = makeSUT(recentFetch: { [makeArrival("신림동"), makeArrival("강남역")] })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.recentRouteChipText == "→ 신림동" }

        #expect(sut.state.recentRouteChipText == "→ 신림동")
    }

    @Test
    func viewDidLoad_noRecentSearch_hidesChip() async {
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.departure == .current(name: "강남역") }
        for _ in 0..<20 { await Task.yield() }

        #expect(sut.state.recentRouteChipText == nil)
    }

    @Test
    func routeSelected_updatesChipImmediatelyAndPromotesArrival() async {
        // 칩은 fetch를 기다리지 않고 즉시 정합하고, 도착지는 save로 승격된다(중복 최신 갱신 재사용).
        let saved = ValueBox([String]())
        let sut = makeSUT(recentSave: { place in saved.update { $0 + [place.name] } })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(
            makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(3600)),
            arrival: makeArrival("당산역")
        )

        #expect(sut.state.recentRouteChipText == "→ 당산역")
        while saved.get().isEmpty { await Task.yield() }
        #expect(saved.get() == ["당산역"])
    }

    @Test
    func chipTapped_success_showsFeaturedCardWithoutRegisteringAlarm() async {
        // 원탭 성공 = routeSelected 수렴 — 카드는 featured(0번), 알람 등록은 0회여야 한다.
        let registerCalls = ValueBox(0)
        let searched = ValueBox([Coordinate]())
        let destination = makeArrival("신림동")
        let featured = makeRoute(id: "featured", departure: fixedNow.addingTimeInterval(3600))
        let alternative = makeRoute(id: "alt", departure: fixedNow.addingTimeInterval(1800))
        let sut = makeSUT(
            register: { _ in registerCalls.update { $0 + 1 } },
            searchRoutes: { start, end in
                searched.update { $0 + [start, end] }
                return .available([featured, alternative])
            },
            recentFetch: { [destination] }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.recentRouteChipText == "→ 신림동" }

        sut.chipTapped()
        await recorder.waitUntilLast { $0.routeCard != nil && !$0.isChipBusy }

        // 재검색 좌표: start = 현재 위치(스텁), end = 칩 도착지.
        #expect(searched.get() == [
            Coordinate(latitude: 37.4979, longitude: 127.0276), destination.coordinate,
        ])
        #expect(sut.state.routeCard == RouteCardViewData(entity: featured, now: fixedNow))
        #expect(sut.state.arrivalText == "신림동")
        #expect(sut.state.alarmButton == .register)
        #expect(sut.state.banner == nil)
        // 알람 자동 등록 금지(확정 결정)의 직접 검증 — 등록은 명시적 버튼 탭만.
        #expect(registerCalls.get() == 0)
        #expect(recorder.toasts.isEmpty)
    }

    @Test
    func chipTapped_locationDenied_reusesPermissionToastAndShowsNoCard() async {
        // 위치 실패 안내는 기존 3분기 이벤트를 재사용한다 — 칩 전용 문구를 만들지 않는다.
        let denied = ValueBox(false)
        let sut = makeSUT(
            location: {
                guard !denied.get() else { throw LocationError.permissionDenied }
                return Coordinate(latitude: 37.4979, longitude: 127.0276)
            },
            recentFetch: { [makeArrival("신림동")] }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        await recorder.waitUntilLast {
            $0.recentRouteChipText == "→ 신림동" && $0.departure == .current(name: "강남역")
        }

        denied.update { _ in true }
        sut.chipTapped()
        while recorder.toasts.isEmpty { await Task.yield() }

        #expect(recorder.toasts == [.locationPermissionNeeded])
        #expect(sut.state.routeCard == nil)
        #expect(!sut.state.isChipBusy)
    }

    @Test
    func chipTapped_locationUnavailable_emitsChipToast() async {
        // 명시적 탭에 무음은 없다 — loadCurrentLocation(무토스트)과 다른 분기.
        let unavailable = ValueBox(false)
        let sut = makeSUT(
            location: {
                guard !unavailable.get() else { throw LocationError.unavailable }
                return Coordinate(latitude: 37.4979, longitude: 127.0276)
            },
            recentFetch: { [makeArrival("신림동")] }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.recentRouteChipText == "→ 신림동" }

        unavailable.update { _ in true }
        sut.chipTapped()
        while recorder.toasts.isEmpty { await Task.yield() }

        #expect(recorder.toasts == [.chipLocationUnavailable])
        #expect(sut.state.routeCard == nil)
    }

    @Test
    func chipTapped_normalizedAndFailedResults_emitMatchingToasts() async {
        // serviceEnded/noRoute/빈 available/실패 전부 토스트만 — 카드·필드는 무변경.
        enum Scenario: Sendable { case serviceEnded, noRoute, emptyAvailable, failure }
        let scenario = ValueBox(Scenario.serviceEnded)
        let sut = makeSUT(
            searchRoutes: { _, _ in
                switch scenario.get() {
                case .serviceEnded: return .serviceEnded
                case .noRoute: return .noRoute
                case .emptyAvailable: return .available([])
                case .failure: throw StubError()
                }
            },
            recentFetch: { [makeArrival("신림동")] }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.recentRouteChipText == "→ 신림동" }

        for (scenarioCase, expected) in [
            (Scenario.serviceEnded, HomeViewModel.ToastEvent.chipServiceEnded),
            (.noRoute, .chipNoRoute),
            (.emptyAvailable, .chipNoRoute),
            (.failure, .chipSearchFailed),
        ] {
            scenario.update { _ in scenarioCase }
            let toastsBefore = recorder.toasts.count
            sut.chipTapped()
            while recorder.toasts.count == toastsBefore { await Task.yield() }
            #expect(recorder.toasts.last == expected)
            await recorder.waitUntilLast { !$0.isChipBusy }
        }
        #expect(sut.state.routeCard == nil)
        #expect(sut.state.arrivalText == nil)
    }

    @Test
    func chipTapped_whileBusy_ignoresSecondTap() async {
        // 더블 탭 = 재검색 1회 — busy 가드가 재진입을 막는다.
        let calls = ValueBox(0)
        let release = ValueBox(false)
        let sut = makeSUT(
            searchRoutes: { _, _ in
                calls.update { $0 + 1 }
                while !release.get() { await Task.yield() }
                return .serviceEnded
            },
            recentFetch: { [makeArrival("신림동")] }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.recentRouteChipText == "→ 신림동" }

        sut.chipTapped()
        #expect(sut.state.isChipBusy)
        sut.chipTapped()
        release.update { _ in true }
        while recorder.toasts.isEmpty { await Task.yield() }

        #expect(calls.get() == 1)
        #expect(recorder.toasts == [.chipServiceEnded])
    }

    @Test
    func viewWillAppear_refetchesChip_reflectingDeletion() async {
        // 검색 화면에서 최근을 지우고 돌아오면 칩도 사라져야 한다 — 재노출 재조회.
        let recents = ValueBox([makeArrival("신림동")])
        let sut = makeSUT(recentFetch: { recents.get() })
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.recentRouteChipText == "→ 신림동" }

        recents.update { _ in [] }
        sut.viewWillAppear()
        await recorder.waitUntilLast { $0.recentRouteChipText == nil }

        #expect(sut.state.recentRouteChipText == nil)
    }

    @Test
    func viewWillAppear_whilePromotionInFlight_keepsJustSelectedChip() async {
        // 승격 저장이 끝나기 전의 재조회는 no-op — 낡은 목록이 방금의 도착지를 덮지 않는다.
        let release = ValueBox(false)
        let sut = makeSUT(
            recentFetch: { [] }, // 저장 전의 낡은(빈) 목록.
            recentSave: { _ in while !release.get() { await Task.yield() } }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(
            makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(3600)),
            arrival: makeArrival("당산역")
        )
        #expect(sut.state.recentRouteChipText == "→ 당산역")

        sut.viewWillAppear()
        for _ in 0..<20 { await Task.yield() }
        #expect(sut.state.recentRouteChipText == "→ 당산역")

        release.update { _ in true }
        for _ in 0..<20 { await Task.yield() }
        #expect(sut.state.recentRouteChipText == "→ 당산역")
    }
}

/// 스탬프 기대값용 포매터 — 프로덕션(HomeViewData)과 같은 구성(HH:mm, ko_KR).
@MainActor
private func makeStampFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.locale = Locale(identifier: "ko_KR")
    return formatter
}

/// 상세 재조회 호출 여부 기록용 — 스텁 클로저가 @Sendable이라 클래스 박스로 관찰한다.
private nonisolated final class FetchFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var flag = false

    var value: Bool {
        lock.lock()
        defer { lock.unlock() }
        return flag
    }

    func mark() {
        lock.lock()
        defer { lock.unlock() }
        flag = true
    }
}

/// 첫 구간이 도보인 경로 픽스처 (Phase 14 도보 반영 검증용).
private nonisolated func makeWalkRoute(id: String, departure: Date, walkSeconds: Int) -> LastRoute {
    let base = makeRoute(id: id, departure: departure)
    let walk = TransportLeg(
        mode: .walk, sectionTime: walkSeconds, distance: 150, departureTime: nil,
        routeName: nil, lineType: nil, start: nil, end: nil,
        subwayFinalStation: nil, subwayDirection: nil,
        isExpressSubway: false, isLastSubway: false
    )
    return LastRoute(
        id: base.id,
        departureTime: base.departureTime,
        totalTime: base.totalTime,
        totalWalkTime: base.totalWalkTime,
        transferCount: base.transferCount,
        totalDistance: base.totalDistance,
        totalWalkDistance: base.totalWalkDistance,
        legs: [walk] + base.legs
    )
}
