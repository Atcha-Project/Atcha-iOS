import Domain
import Foundation
@testable import HomeFeature
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
    func execute(route: LastRoute) async throws { try await handler(route) }
}

private struct StubCancelAlarmUseCase: CancelAlarmUseCase {
    let handler: @Sendable (String) async throws -> Void
    func execute(lastRouteId: String) async throws { try await handler(lastRouteId) }
}

private struct StubObserveAlarmUseCase: ObserveAlarmUseCase {
    let handler: @Sendable () -> AsyncStream<AlarmInfo>
    func execute() -> AsyncStream<AlarmInfo> { handler() }
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
    cancel: @escaping @Sendable (String) async throws -> Void = { _ in },
    alarmUpdates: @escaping @Sendable () -> AsyncStream<AlarmInfo> = {
        AsyncStream { $0.finish() }
    },
    now: @escaping @Sendable () -> Date = { fixedNow },
    bannerTickInterval: Duration = .seconds(60)
) -> HomeViewModel {
    HomeViewModel(
        getCurrentLocationUseCase: StubGetCurrentLocationUseCase(handler: location),
        reverseGeocodeUseCase: StubReverseGeocodeUseCase(handler: geocode),
        registerAlarmUseCase: StubRegisterAlarmUseCase(handler: register),
        cancelAlarmUseCase: StubCancelAlarmUseCase(handler: cancel),
        observeAlarmUseCase: StubObserveAlarmUseCase(handler: alarmUpdates),
        now: now,
        bannerTickInterval: bannerTickInterval
    )
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
        await recorder.waitUntilLast { $0.departure == .needsSearch(deniedPermission: true) }

        #expect(recorder.toasts == [.locationPermissionNeeded])
    }

    @Test
    func viewDidLoad_otherFailure_needsSearchWithoutToast() async {
        let sut = makeSUT(geocode: { _ in throw StubError() })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { $0.departure == .needsSearch(deniedPermission: false) }

        #expect(recorder.toasts.isEmpty)
    }

    @Test
    func routeSelected_populatesCard() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route)

        #expect(sut.state.routeCard == RouteCardViewData(entity: route))
        #expect(sut.state.banner == nil)
    }

    @Test
    func registerAlarm_success_startsBannerCountdown() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT()
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route)
        sut.registerAlarmTapped()
        #expect(sut.state.isAlarmBusy)
        await recorder.waitUntilLast { $0.banner != nil }

        #expect(sut.state.banner == .init(text: "막차 출발까지 42분", isUrgent: false))
        #expect(!sut.state.isAlarmBusy)
        // 등록 성공 후 같은 자리 버튼이 해제로 토글된다.
        #expect(sut.state.alarmButton == .cancel)
    }

    @Test
    func registerAlarm_failure_emitsToastAndKeepsBannerHidden() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT(register: { _ in throw StubError() })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route)
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
        sut.routeSelected(route)
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil }

        sut.routeSelected(makeRoute(id: "r2", departure: fixedNow.addingTimeInterval(30 * 60)))

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

        #expect(HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(10 * 60), now: fixedNow
        ).isUrgent)
        #expect(!HomeViewModel.makeBanner(
            departure: fixedNow.addingTimeInterval(11 * 60), now: fixedNow
        ).isUrgent)
        #expect(HomeViewModel.makeBanner(
            departure: fixedNow, now: fixedNow
        ) == .init(text: "막차 출발까지 0분", isUrgent: true))
    }

    @Test
    func bannerTimer_ticksRecomputeMinutes() async {
        let clock = NowBox(fixedNow)
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT(now: { clock.get() }, bannerTickInterval: .milliseconds(1))
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route)
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner?.text == "막차 출발까지 42분" }

        clock.set(fixedNow.addingTimeInterval(40 * 60))
        await recorder.waitUntilLast { $0.banner?.text == "막차 출발까지 2분" }

        #expect(sut.state.banner?.isUrgent == true)
    }

    @Test
    func registerAlarm_permissionDenied_emitsSettingsToast() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let sut = makeSUT(register: { _ in throw AlarmError.permissionDenied })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.routeSelected(route)
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
        sut.routeSelected(route)
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
        sut.routeSelected(route)
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
        let (stream, continuation) = AsyncStream<AlarmInfo>.makeStream()
        let sut = makeSUT(alarmUpdates: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        continuation.yield(
            AlarmInfo(lastRouteId: "r1", departureTime: departure, updatedAt: nil, isReal: true)
        )
        await recorder.waitUntilLast { $0.banner != nil }

        #expect(sut.state.banner == .init(text: "막차 출발까지 30분", isUrgent: false))
        #expect(sut.state.alarmButton == .cancel)
        #expect(sut.state.routeCard == nil)
    }

    @Test
    func alarmSync_updatesBannerToNewDeparture() async {
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let (stream, continuation) = AsyncStream<AlarmInfo>.makeStream()
        let sut = makeSUT(alarmUpdates: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        sut.viewDidLoad()
        sut.routeSelected(route)
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner?.text == "막차 출발까지 42분" }

        // 서버가 15분 당긴 시각을 돌려준다 (포그라운드 복귀·푸시 동기화 공용 경로).
        continuation.yield(
            AlarmInfo(
                lastRouteId: "r1",
                departureTime: fixedNow.addingTimeInterval(27 * 60),
                updatedAt: nil,
                isReal: true
            )
        )
        await recorder.waitUntilLast { $0.banner?.text == "막차 출발까지 27분" }

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
}
