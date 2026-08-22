import Domain
import Foundation
@testable import SearchFeature
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
    store: RecentStore = RecentStore()
) -> SearchViewModel {
    SearchViewModel(
        searchPlacesUseCase: StubSearchPlacesUseCase(handler: placesHandler),
        searchLastRoutesUseCase: StubSearchLastRoutesUseCase(handler: routesHandler),
        recentSearchesUseCase: StubRecentSearchesUseCase(store: store),
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
        let expected = RouteResultsViewData(entities: routes, isExpanded: false)
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
        #expect(recorder.states.last == .routes(RouteResultsViewData(entities: routes, isExpanded: true)))

        sut.didTapMore()
        #expect(recorder.states.last == .routes(RouteResultsViewData(entities: routes, isExpanded: false)))
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
    func selectRoute_forwardsEntityToOnRouteChosen() async {
        let routes = [makeRoute(id: "r1"), makeRoute(id: "r2")]
        let sut = makeSUT(
            placesHandler: { _ in [makePlace("강남역")] },
            routesHandler: { .available(routes) }
        )
        var chosen: LastRoute?
        sut.onRouteChosen = { chosen = $0 }
        let recorder = StateRecorder()
        recorder.attach(to: sut)
        await driveBothSlotsConfirmed(sut: sut, recorder: recorder)
        await recorder.waitUntilLast { if case .routes = $0 { true } else { false } }

        sut.didSelectRoute(at: 0)

        #expect(chosen == routes[0])
    }
}
