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

private struct StubObserveAlarmChangeUseCase: ObserveAlarmChangeUseCase {
    let handler: @Sendable () -> AsyncStream<AlarmChangeVerdict>
    func execute() -> AsyncStream<AlarmChangeVerdict> { handler() }
}

private struct StubGetLastRouteDetailUseCase: GetLastRouteDetailUseCase {
    let handler: @Sendable (String) async throws -> LastRoute
    func execute(routeId: String) async throws -> LastRoute { try await handler(routeId) }
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
    alarmChanges: @escaping @Sendable () -> AsyncStream<AlarmChangeVerdict> = {
        AsyncStream { $0.finish() }
    },
    routeDetail: @escaping @Sendable (String) async throws -> LastRoute = { _ in
        throw StubError()
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
        observeAlarmChangeUseCase: StubObserveAlarmChangeUseCase(handler: alarmChanges),
        getLastRouteDetailUseCase: StubGetLastRouteDetailUseCase(handler: routeDetail),
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

        // 카운트다운은 버퍼(3분) 포함 알람 발화 시각 기준 — 42분 출발이면 39분.
        #expect(sut.state.banner == .init(text: "출발까지 39분", urgency: .relaxed))
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
        sut.routeSelected(route)
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

        sut.routeSelected(route)
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

        // 30분 출발 → 알람까지 27분(1620초) — caution 구간.
        #expect(sut.state.banner == .init(text: "출발까지 27분", urgency: .caution))
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
        await recorder.waitUntilLast { $0.banner?.text == "출발까지 39분" }

        // 서버가 15분 당긴 시각을 돌려준다 (포그라운드 복귀·푸시 동기화 공용 경로).
        continuation.yield(
            AlarmInfo(
                lastRouteId: "r1",
                departureTime: fixedNow.addingTimeInterval(27 * 60),
                updatedAt: nil,
                isReal: true
            )
        )
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
        sut.routeSelected(route)
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
        sut.routeSelected(route)
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
        let (stream, continuation) = AsyncStream<AlarmInfo>.makeStream()
        let sut = makeSUT(alarmUpdates: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        continuation.yield(
            AlarmInfo(
                lastRouteId: "r1",
                departureTime: fixedNow.addingTimeInterval(-60),
                updatedAt: nil,
                isReal: true
            )
        )
        await recorder.waitUntilLast { $0.alarmButton == .cancel }

        #expect(sut.state.banner == nil)
    }

    @Test
    func alarmSync_withinGrace_restoresDepartNowBanner() async {
        // 발화~유예 창의 동기화 복원 — 2단계 "지금 출발하세요"도 복원 대상이다 (Phase 13).
        let (stream, continuation) = AsyncStream<AlarmInfo>.makeStream()
        let sut = makeSUT(alarmUpdates: { stream })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        continuation.yield(
            AlarmInfo(
                lastRouteId: "r1",
                departureTime: fixedNow.addingTimeInterval(-30),
                updatedAt: nil,
                isReal: true
            )
        )
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

        sut.routeSelected(route)
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

        sut.routeSelected(route)
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
        let (stream, continuation) = AsyncStream<AlarmInfo>.makeStream()
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
        continuation.yield(
            AlarmInfo(lastRouteId: "r1", departureTime: departure, updatedAt: nil, isReal: true)
        )
        await recorder.waitUntilLast { $0.routeCard != nil }

        #expect(sut.state.routeCard == RouteCardViewData(entity: route))
        #expect(sut.state.alarmButton == .cancel)
        // 배너도 상세의 도보 초 반영 기준으로 재시작됐다 (42분 − 2분 도보 − 3분 버퍼 = 37분).
        await recorder.waitUntilLast { $0.banner?.text == "출발까지 37분" }
    }

    @Test
    func alarmSync_detailFails_keepsCancelButtonWithoutCard() async {
        // 복원 실패는 현행 폴백 — 카드 없이 해제 버튼·배너만. (기본 routeDetail 스텁이 throw)
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
        for _ in 0..<20 { await Task.yield() }

        #expect(sut.state.routeCard == nil)
        #expect(sut.state.alarmButton == .cancel)
    }

    @Test
    func alarmSync_cardAlreadyVisible_doesNotFetchDetail() async {
        // 등록 직후의 동기화 — 카드가 이미 있으면 상세 재조회를 하지 않는다.
        let route = makeRoute(id: "r1", departure: fixedNow.addingTimeInterval(42 * 60))
        let fetched = FetchFlag()
        let (stream, continuation) = AsyncStream<AlarmInfo>.makeStream()
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
        sut.routeSelected(route)
        sut.registerAlarmTapped()
        await recorder.waitUntilLast { $0.banner != nil }

        continuation.yield(
            AlarmInfo(
                lastRouteId: "r1",
                departureTime: fixedNow.addingTimeInterval(42 * 60),
                updatedAt: nil,
                isReal: true
            )
        )
        for _ in 0..<20 { await Task.yield() }

        #expect(!fetched.value)
        #expect(sut.state.routeCard == RouteCardViewData(entity: route))
    }
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
