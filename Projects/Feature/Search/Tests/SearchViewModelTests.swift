import Domain
import Foundation
@testable import SearchFeature
import SearchFeatureInterface
import Testing

private struct StubSearchPlacesUseCase: SearchPlacesUseCase {
    let handler: @Sendable (String) async throws -> [Place]
    func execute(keyword: String, near coordinate: Coordinate?) async throws -> [Place] {
        try await handler(keyword)
    }
}

private struct StubSearchLastRoutesUseCase: SearchLastRoutesUseCase {
    let handler: @Sendable () async throws -> LastRouteSearchResult
    func execute(start: Coordinate, end: Coordinate) async throws -> LastRouteSearchResult {
        try await handler()
    }
}

private struct StubGetCurrentLocationUseCase: GetCurrentLocationUseCase {
    let handler: @Sendable () async throws -> Coordinate
    func execute() async throws -> Coordinate { try await handler() }
}

// 키워드 검색이 받은 near 좌표를 기록한다.
private actor NearLog {
    private(set) var coordinates: [Coordinate?] = []
    func append(_ coordinate: Coordinate?) { coordinates.append(coordinate) }
}

private struct NearRecordingSearchPlacesUseCase: SearchPlacesUseCase {
    let log: NearLog
    let places: [Place]

    func execute(keyword: String, near coordinate: Coordinate?) async throws -> [Place] {
        await log.append(coordinate)
        return places
    }
}

// save/remove 호출 기록 + fetch 응답을 한곳에서 관리.
private actor RecentStore {
    private(set) var saved: [Place] = []
    private(set) var removed: [Place] = []
    private var places: [Place]

    init(places: [Place] = []) {
        self.places = places
    }

    func save(_ place: Place) {
        saved.append(place)
        places.removeAll { $0 == place }
        places.insert(place, at: 0)
    }

    func remove(_ place: Place) {
        removed.append(place)
        places.removeAll { $0 == place }
    }

    func fetch() -> [Place] { places }
}

private struct StubRecentSearchesUseCase: RecentSearchesUseCase {
    let store: RecentStore
    func fetch() async throws -> [Place] { await store.fetch() }
    func save(_ place: Place) async throws { await store.save(place) }
    func remove(_ place: Place) async throws { await store.remove(place) }
}

private struct StubError: Error {}

// MARK: - 헬퍼

@MainActor
private final class StateRecorder {
    private(set) var states: [SearchViewModel.State] = []

    func attach(to sut: SearchViewModel) {
        sut.onStateChange = { [weak self] state in
            self?.states.append(state)
        }
    }

    // Home 템플릿의 드레인 패턴: 스텁이 즉시 resolve하므로 yield로 충분하다.
    func waitUntilLast(_ predicate: (SearchViewModel.State) -> Bool) async {
        while !(states.last.map(predicate) ?? false) {
            await Task.yield()
        }
    }
}

private nonisolated let fixedNow = Date(timeIntervalSince1970: 1_755_800_000)

private nonisolated func makePlace(_ name: String) -> Place {
    Place(
        name: name,
        address: "서울 \(name) 주소",
        coordinate: Coordinate(latitude: 37.5, longitude: 127.0)
    )
}

private nonisolated func makeRoute(id: String, departureOffset: TimeInterval = 0) -> LastRoute {
    LastRoute(
        id: id,
        departureTime: Date(timeIntervalSince1970: 1_755_800_000 + departureOffset),
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
    placesHandler: @escaping @Sendable (String) async throws -> [Place] = { _ in [] },
    routesHandler: @escaping @Sendable () async throws -> LastRouteSearchResult = { .available([]) },
    store: RecentStore = RecentStore(),
    location: (@Sendable () async throws -> Coordinate)? = nil,
    initialField: SearchEntryField = .departure
) -> SearchViewModel {
    SearchViewModel(
        searchPlacesUseCase: StubSearchPlacesUseCase(handler: placesHandler),
        searchLastRoutesUseCase: StubSearchLastRoutesUseCase(handler: routesHandler),
        recentSearchesUseCase: StubRecentSearchesUseCase(store: store),
        getCurrentLocationUseCase: location.map(StubGetCurrentLocationUseCase.init(handler:)),
        initialField: initialField,
        now: { fixedNow },
        debounceInterval: .zero
    )
}

/// 최근 선택 → 도착지 키워드 검색 → 선택으로 두 슬롯을 확정해 경로 검색을 발동시킨다.
@MainActor
private func driveBothSlotsConfirmed(sut: SearchViewModel, recorder: StateRecorder) async {
    sut.viewDidLoad()
    await recorder.waitUntilLast { if case .recent = $0 { true } else { false } }
    sut.keywordDidChange("강남", in: .departure)
    await recorder.waitUntilLast { if case .places = $0 { true } else { false } }
    sut.didSelectListItem(at: 0)
    await recorder.waitUntilLast { if case .recent = $0 { true } else { false } }
    sut.keywordDidChange("회사", in: .arrival)
    await recorder.waitUntilLast { if case .places = $0 { true } else { false } }
    sut.didSelectListItem(at: 0)
}

// MARK: - 테스트

@MainActor
struct SearchViewModelTests {
    @Test
    func viewDidLoad_loadsRecentSearches() async {
        let recents = [makePlace("강남역"), makePlace("홍대입구역")]
        let sut = makeSUT(store: RecentStore(places: recents))
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { if case .recent = $0 { true } else { false } }

        #expect(recorder.states.last == .recent(recents.map(PlaceViewData.init(entity:))))
    }

    @Test
    func keywordChange_cancelsPreviousSearch() async {
        let stale = makePlace("스테일")
        let fresh = makePlace("프레시")
        let sut = makeSUT(placesHandler: { keyword in
            if keyword == "강" {
                try await Task.sleep(for: .seconds(2))
                return [stale]
            }
            return [fresh]
        })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.keywordDidChange("강", in: .departure)
        await Task.yield()
        sut.keywordDidChange("강남", in: .departure)
        await recorder.waitUntilLast { $0 == .places([PlaceViewData(entity: fresh)]) }

        #expect(!recorder.states.contains(.places([PlaceViewData(entity: stale)])))
        #expect(!recorder.states.contains { if case .failed = $0 { true } else { false } })
    }

    @Test
    func bothSlotsConfirmed_success_showsFeaturedRouteFirst() async {
        let routes = [makeRoute(id: "r1"), makeRoute(id: "r2", departureOffset: -600)]
        let place = makePlace("강남역")
        let sut = makeSUT(
            placesHandler: { _ in [place] },
            routesHandler: { .available(routes) }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        await driveBothSlotsConfirmed(sut: sut, recorder: recorder)
        await recorder.waitUntilLast { if case .routes = $0 { true } else { false } }

        #expect(recorder.states.contains(.loadingRoutes))
        let expected = RouteResultsViewData(entities: routes, isExpanded: false, now: fixedNow)
        #expect(recorder.states.last == .routes(expected))
        #expect(expected.featured.badgeText == "가장 늦은 차")
        #expect(expected.alternatives.count == 1)
    }

    @Test
    func routeSearch_serviceEnded_showsServiceEnded() async {
        let sut = makeSUT(
            placesHandler: { _ in [makePlace("강남역")] },
            routesHandler: { .serviceEnded }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        await driveBothSlotsConfirmed(sut: sut, recorder: recorder)
        await recorder.waitUntilLast { $0 == .serviceEnded }

        #expect(recorder.states.last == .serviceEnded)
    }

    @Test
    func routeSearch_noRoute_showsNoRoute() async {
        let sut = makeSUT(
            placesHandler: { _ in [makePlace("강남역")] },
            routesHandler: { .noRoute }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        await driveBothSlotsConfirmed(sut: sut, recorder: recorder)
        await recorder.waitUntilLast { $0 == .noRoute }

        #expect(recorder.states.last == .noRoute)
    }

    @Test
    func placeSearch_failure_showsFailedMessage() async {
        let sut = makeSUT(placesHandler: { _ in throw StubError() })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.keywordDidChange("강남", in: .departure)
        await recorder.waitUntilLast { if case .failed = $0 { true } else { false } }

        #expect(recorder.states.last == .failed(message: "검색에 실패했어요"))
    }

    @Test
    func routeSearch_failure_showsFailedMessage() async {
        let sut = makeSUT(
            placesHandler: { _ in [makePlace("강남역")] },
            routesHandler: { throw StubError() }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        await driveBothSlotsConfirmed(sut: sut, recorder: recorder)
        await recorder.waitUntilLast { if case .failed = $0 { true } else { false } }

        #expect(recorder.states.last == .failed(message: "막차를 찾지 못했어요"))
    }

    @Test
    func didTapMore_togglesAlternativesExpansion() async {
        let routes = [makeRoute(id: "r1"), makeRoute(id: "r2"), makeRoute(id: "r3")]
        let sut = makeSUT(
            placesHandler: { _ in [makePlace("강남역")] },
            routesHandler: { .available(routes) }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        await driveBothSlotsConfirmed(sut: sut, recorder: recorder)
        await recorder.waitUntilLast { if case .routes = $0 { true } else { false } }

        sut.didTapMore()
        #expect(recorder.states.last == .routes(RouteResultsViewData(entities: routes, isExpanded: true, now: fixedNow)))

        sut.didTapMore()
        #expect(recorder.states.last == .routes(RouteResultsViewData(entities: routes, isExpanded: false, now: fixedNow)))
    }

    @Test
    func selectPlace_savesRecentAndMovesFocusToArrival() async {
        let place = makePlace("강남역")
        let store = RecentStore()
        let sut = makeSUT(placesHandler: { _ in [place] }, store: store)
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.keywordDidChange("강남", in: .departure)
        await recorder.waitUntilLast { if case .places = $0 { true } else { false } }
        sut.didSelectListItem(at: 0)
        await recorder.waitUntilLast { if case .recent = $0 { true } else { false } }

        #expect(await store.saved == [place])
        #expect(sut.fields.departureText == "강남역")
        #expect(sut.fields.activeField == .arrival)
    }

    @Test
    func deleteRecent_removesAndReloadsList() async {
        let first = makePlace("강남역")
        let second = makePlace("홍대입구역")
        let store = RecentStore(places: [first, second])
        let sut = makeSUT(store: store)
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { if case .recent = $0 { true } else { false } }
        sut.didDeleteRecent(at: 0)
        await recorder.waitUntilLast { $0 == .recent([PlaceViewData(entity: second)]) }

        #expect(await store.removed == [first])
    }

    @Test
    func viewDidLoad_withLocation_prefillsDepartureAsCurrentLocation() async {
        let coordinate = Coordinate(latitude: 37.49, longitude: 127.02)
        let sut = makeSUT(location: { coordinate })

        sut.viewDidLoad()
        while sut.fields.departureText.isEmpty { await Task.yield() }

        #expect(sut.fields.departureText == "현재 위치")
        #expect(sut.fields.activeField == .arrival)
    }

    @Test
    func viewDidLoad_locationFails_keepsDepartureEmpty() async {
        let sut = makeSUT(location: { throw StubError() })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        await recorder.waitUntilLast { if case .recent = $0 { true } else { false } }
        for _ in 0..<20 { await Task.yield() }

        #expect(sut.fields.departureText.isEmpty)
        #expect(sut.fields.activeField == .departure)
    }

    @Test
    func latePrefill_doesNotOverwriteTypedDeparture() async {
        let (stream, continuation) = AsyncStream.makeStream(of: Coordinate.self)
        let sut = makeSUT(
            placesHandler: { _ in [makePlace("강남역")] },
            location: {
                for await coordinate in stream { return coordinate }
                throw StubError()
            }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        sut.keywordDidChange("강남", in: .departure)
        await recorder.waitUntilLast { if case .places = $0 { true } else { false } }

        continuation.yield(Coordinate(latitude: 37.49, longitude: 127.02))
        continuation.finish()
        for _ in 0..<20 { await Task.yield() }

        #expect(sut.fields.departureText == "강남")
    }

    @Test
    func keywordSearch_afterPrefill_passesNearBias() async {
        let coordinate = Coordinate(latitude: 37.49, longitude: 127.02)
        let log = NearLog()
        let sut = SearchViewModel(
            searchPlacesUseCase: NearRecordingSearchPlacesUseCase(log: log, places: [makePlace("회사")]),
            searchLastRoutesUseCase: StubSearchLastRoutesUseCase(handler: { .available([]) }),
            recentSearchesUseCase: StubRecentSearchesUseCase(store: RecentStore()),
            getCurrentLocationUseCase: StubGetCurrentLocationUseCase(handler: { coordinate }),
            debounceInterval: .zero
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        while sut.fields.departureText.isEmpty { await Task.yield() }
        sut.keywordDidChange("회사", in: .arrival)
        await recorder.waitUntilLast { if case .places = $0 { true } else { false } }

        #expect(await log.coordinates == [coordinate])
    }

    @Test
    func prefillThenArrivalConfirmed_searchesRoutes() async {
        let routes = [makeRoute(id: "r1")]
        let sut = makeSUT(
            placesHandler: { _ in [makePlace("회사")] },
            routesHandler: { .available(routes) },
            location: { Coordinate(latitude: 37.49, longitude: 127.02) }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.viewDidLoad()
        while sut.fields.departureText.isEmpty { await Task.yield() }
        sut.keywordDidChange("회사", in: .arrival)
        await recorder.waitUntilLast { if case .places = $0 { true } else { false } }
        sut.didSelectListItem(at: 0)
        await recorder.waitUntilLast { if case .routes = $0 { true } else { false } }

        #expect(recorder.states.last == .routes(RouteResultsViewData(entities: routes, isExpanded: false, now: fixedNow)))
    }

    @Test
    func selectRoute_forwardsEntityAndConfirmedArrival() async {
        // 도착지 동반(Phase 17) — 홈 도착지 필드의 원천이므로 확정된 그 장소여야 한다.
        let arrival = makePlace("회사")
        let routes = [makeRoute(id: "r1"), makeRoute(id: "r2")]
        let sut = makeSUT(
            placesHandler: { _ in [arrival] },
            routesHandler: { .available(routes) }
        )
        var chosen: LastRoute?
        var chosenArrival: Place?
        sut.onRouteChosen = { route, place in
            chosen = route
            chosenArrival = place
        }
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        await driveBothSlotsConfirmed(sut: sut, recorder: recorder)
        await recorder.waitUntilLast { if case .routes = $0 { true } else { false } }

        sut.didSelectRoute(at: 0)

        #expect(chosen == routes[0])
        #expect(chosenArrival == arrival)
    }

    // MARK: - Phase 17: 진입 필드·로딩·빈 결과·다시 검색하기·내일 라벨

    @Test
    func initialFieldArrival_startsWithArrivalSlotActive() {
        let sut = makeSUT(initialField: .arrival)
        #expect(sut.fields.activeField == .arrival)

        let departureEntry = makeSUT(initialField: .departure)
        #expect(departureEntry.fields.activeField == .departure)
    }

    @Test
    func keywordSearch_passesThroughLoadingPlaces() async {
        let place = makePlace("강남역")
        let sut = makeSUT(placesHandler: { _ in [place] })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.keywordDidChange("강남", in: .departure)
        await recorder.waitUntilLast { if case .places = $0 { true } else { false } }

        // 디바운스 통과 후 요청 직전의 로딩 상태를 반드시 거친다.
        #expect(recorder.states.contains(.loadingPlaces))
    }

    @Test
    func keywordSearch_zeroResults_showsEmptyPlaces() async {
        let sut = makeSUT(placesHandler: { _ in [] })
        let recorder = StateRecorder()
        recorder.attach(to: sut)

        sut.keywordDidChange("결과없는키워드", in: .arrival)
        await recorder.waitUntilLast { $0 == .places([]) }

        // 0건도 .places로 흐른다 — VC가 빈 상태("검색 결과가 없어요")를 그린다.
        #expect(recorder.states.last == .places([]))
    }

    @Test
    func emptyResultAction_resetsArrivalSlotAndReturnsToRecent() async {
        // "다시 검색하기" 실동작: 도착지 슬롯 초기화 + 포커스 + 최근 검색 복귀.
        let sut = makeSUT(
            placesHandler: { _ in [makePlace("강남역")] },
            routesHandler: { .serviceEnded }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        await driveBothSlotsConfirmed(sut: sut, recorder: recorder)
        await recorder.waitUntilLast { $0 == .serviceEnded }
        #expect(!sut.fields.arrivalText.isEmpty)

        sut.didTapEmptyAction()
        await recorder.waitUntilLast { if case .recent = $0 { true } else { false } }

        #expect(sut.fields.arrivalText.isEmpty)
        #expect(sut.fields.activeField == .arrival)
        // 출발지는 유지 — 즉시 새 도착지 검색이 가능하다.
        #expect(sut.fields.departureText == "강남역")
    }

    @Test
    func noRouteAction_alsoResetsArrivalSlot() async {
        let sut = makeSUT(
            placesHandler: { _ in [makePlace("강남역")] },
            routesHandler: { .noRoute }
        )
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        await driveBothSlotsConfirmed(sut: sut, recorder: recorder)
        await recorder.waitUntilLast { $0 == .noRoute }

        sut.didTapEmptyAction()
        await recorder.waitUntilLast { if case .recent = $0 { true } else { false } }

        #expect(sut.fields.arrivalText.isEmpty)
        #expect(sut.fields.activeField == .arrival)
    }

    @Test
    func dayPrefix_labelsOnlyTomorrow() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let now = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 23, hour: 23, minute: 40)
        )!
        let lateTonight = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 23, hour: 23, minute: 55)
        )!
        let afterMidnight = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 24, hour: 0, minute: 29)
        )!
        let dayAfterTomorrow = calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 25, hour: 0, minute: 10)
        )!

        #expect(dayPrefix(for: lateTonight, now: now, calendar: calendar) == "")
        #expect(dayPrefix(for: afterMidnight, now: now, calendar: calendar) == "내일 ")
        // 이틀+ 미래는 막차 도메인상 비발생 — 방어적 무라벨.
        #expect(dayPrefix(for: dayAfterTomorrow, now: now, calendar: calendar) == "")
    }

    @Test
    func routeViewData_labelsTomorrowDepartureAndArrival() {
        let tomorrowDeparture = Calendar.current.date(byAdding: .day, value: 1, to: fixedNow)!
        let tomorrow = RouteViewData(
            entity: makeRoute(id: "r1", departureOffset: tomorrowDeparture.timeIntervalSince(fixedNow)),
            isFeatured: true,
            now: fixedNow
        )
        #expect(tomorrow.departureTimeText.hasPrefix("내일 "))
        #expect(tomorrow.destinationText.hasPrefix("도착 내일 "))

        // 오늘 출발·오늘 도착은 무라벨 — 무라벨 = 오늘.
        let today = RouteViewData(
            entity: makeRoute(id: "r2", departureOffset: 60), isFeatured: true, now: fixedNow
        )
        #expect(!today.departureTimeText.hasPrefix("내일 "))
        #expect(!today.destinationText.contains("내일"))
    }
}
