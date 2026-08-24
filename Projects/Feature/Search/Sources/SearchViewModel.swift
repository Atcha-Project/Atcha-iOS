import Domain
import Foundation
import SearchFeatureInterface

// Convention: every ViewModel in the codebase is @MainActor.
@MainActor
final class SearchViewModel {
    enum Field: Equatable {
        case departure
        case arrival
    }

    /// 콘텐츠 영역(입력 필드 아래)의 표시 상태.
    /// 불변식: `.loadingRoutes`/`.routes`는 두 슬롯이 모두 확정일 때만 존재한다.
    enum State: Equatable {
        case idle
        case recent([PlaceViewData])
        case places([PlaceViewData])
        /// 키워드 검색 진행 중(Phase 17) — 디바운스 통과 후에만 진입한다(타이핑 깜빡임 방지).
        case loadingPlaces
        case loadingRoutes
        case routes(RouteResultsViewData)
        case serviceEnded
        case noRoute
        case failed(message: String)
    }

    /// 상단 입력 슬롯 영역의 표시 상태. VC는 텍스트 diff 후 setText로만 반영한다.
    struct FieldsViewData: Equatable {
        var departureText: String
        var arrivalText: String
        var activeField: Field
    }

    /// Set by the ViewController; always invoked on the main actor.
    var onStateChange: ((State) -> Void)?
    var onFieldsChange: ((FieldsViewData) -> Void)?
    /// Set by the Coordinator. Place = 확정 도착지 — 홈 도착지 필드의 원천이다(Phase 17).
    var onRouteChosen: ((LastRoute, Place) -> Void)?
    var onBackRequested: (() -> Void)?

    private(set) var state: State = .idle {
        didSet { onStateChange?(state) }
    }

    private(set) var fields = FieldsViewData(
        departureText: "",
        arrivalText: "",
        activeField: .departure
    ) {
        didSet { if fields != oldValue { onFieldsChange?(fields) } }
    }

    // 확정된 슬롯. 타이핑이 시작되면 해당 슬롯은 다시 미확정으로 돌아간다.
    private var departure: Place?
    private var arrival: Place?
    // 확보되면 키워드 검색의 near 바이어스로 쓴다.
    private var currentCoordinate: Coordinate?
    // 현재 리스트(.recent/.places)에 표시 중인 원본 — index 선택 매핑용.
    private var listedPlaces: [Place] = []
    // 0번 = 가장 늦은 차.
    private var availableRoutes: [LastRoute] = []
    private var isExpanded = false

    private let searchPlacesUseCase: any SearchPlacesUseCase
    private let searchLastRoutesUseCase: any SearchLastRoutesUseCase
    private let recentSearchesUseCase: any RecentSearchesUseCase
    // nil이면(예: Example 스텁 구성) 프리필·near 바이어스 없이 동작한다.
    private let getCurrentLocationUseCase: (any GetCurrentLocationUseCase)?
    // 오늘/내일 라벨 판정의 기준 시각(Phase 17) — 실 Date() 직접 호출 대신 주입(기존 VM 관례).
    private let now: @Sendable () -> Date
    private let debounceInterval: Duration

    private var searchTask: Task<Void, Never>?
    private var routeTask: Task<Void, Never>?
    private var recentTask: Task<Void, Never>?
    private var locationTask: Task<Void, Never>?
    // save는 fetch류와 분리 보관 — 목록 갱신이 저장을 cancel하면 안 된다.
    private var saveTask: Task<Void, Never>?

    init(
        searchPlacesUseCase: any SearchPlacesUseCase,
        searchLastRoutesUseCase: any SearchLastRoutesUseCase,
        recentSearchesUseCase: any RecentSearchesUseCase,
        getCurrentLocationUseCase: (any GetCurrentLocationUseCase)? = nil,
        initialField: SearchEntryField = .departure,
        now: @escaping @Sendable () -> Date = { Date() },
        debounceInterval: Duration = .milliseconds(300)
    ) {
        self.searchPlacesUseCase = searchPlacesUseCase
        self.searchLastRoutesUseCase = searchLastRoutesUseCase
        self.recentSearchesUseCase = recentSearchesUseCase
        self.getCurrentLocationUseCase = getCurrentLocationUseCase
        self.now = now
        self.debounceInterval = debounceInterval
        // 탭한 필드로 진입한다(Phase 17) — 초기 활성 슬롯만 정하고 프리필 정책은 불변.
        fields.activeField = (initialField == .arrival) ? .arrival : .departure
    }

    deinit {
        searchTask?.cancel()
        routeTask?.cancel()
        recentTask?.cancel()
        locationTask?.cancel()
        saveTask?.cancel()
    }

    // MARK: - 입력

    func viewDidLoad() {
        showRecent()
        prefillDepartureWithCurrentLocation()
    }

    func fieldDidBeginEditing(_ field: Field) {
        fields.activeField = field
        let isConfirmed = (field == .departure) ? departure != nil : arrival != nil
        switch state {
        case .recent, .places:
            break
        default:
            if !isConfirmed { showRecent() }
        }
    }

    func keywordDidChange(_ keyword: String, in field: Field) {
        // 타이핑 = 확정 해제. 경로 검색 결과도 더 이상 유효하지 않다.
        switch field {
        case .departure: departure = nil
        case .arrival: arrival = nil
        }
        var newFields = fields
        newFields.activeField = field
        switch field {
        case .departure: newFields.departureText = keyword
        case .arrival: newFields.arrivalText = keyword
        }
        fields = newFields

        searchTask?.cancel()
        routeTask?.cancel()

        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showRecent()
            return
        }

        // [weak self]: the in-flight task must not keep the ViewModel alive.
        searchTask = Task { [weak self] in
            guard let interval = self?.debounceInterval,
                  let useCase = self?.searchPlacesUseCase else { return }
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            // 디바운스 통과 = 이 키워드로 실제 요청한다 — 로딩은 여기서부터(Phase 17).
            self?.state = .loadingPlaces
            do {
                // 현재 위치가 확보된 경우에만 근처 우선 정렬 바이어스를 건다.
                let places = try await useCase.execute(keyword: trimmed, near: self?.currentCoordinate)
                guard !Task.isCancelled else { return }
                self?.listedPlaces = places
                self?.state = .places(places.map(PlaceViewData.init(entity:)))
            } catch {
                guard !Task.isCancelled else { return }
                self?.state = .failed(message: "검색에 실패했어요")
            }
        }
    }

    func didSelectListItem(at index: Int) {
        switch state {
        case .recent, .places:
            break
        default:
            return
        }
        guard listedPlaces.indices.contains(index) else { return }
        confirm(listedPlaces[index], in: fields.activeField)
    }

    func didDeleteRecent(at index: Int) {
        guard case .recent = state, listedPlaces.indices.contains(index) else { return }
        let place = listedPlaces[index]
        recentTask?.cancel()
        recentTask = Task { [weak self] in
            guard let useCase = self?.recentSearchesUseCase else { return }
            try? await useCase.remove(place)
            let places = (try? await useCase.fetch()) ?? []
            guard !Task.isCancelled else { return }
            self?.listedPlaces = places
            self?.state = .recent(places.map(PlaceViewData.init(entity:)))
        }
    }

    func didTapMore() {
        guard case .routes = state, !availableRoutes.isEmpty else { return }
        isExpanded.toggle()
        state = .routes(
            RouteResultsViewData(entities: availableRoutes, isExpanded: isExpanded, now: now())
        )
    }

    func didSelectRoute(at index: Int) {
        guard case .routes = state, availableRoutes.indices.contains(index) else { return }
        // 불변식: routes 상태는 두 슬롯 확정 시에만 존재한다 — arrival은 항상 있다(방어 가드).
        guard let arrival else { return }
        onRouteChosen?(availableRoutes[index], arrival)
    }

    func didTapEmptyAction() {
        switch state {
        case .failed where departure != nil && arrival != nil:
            searchRoutes()
        case .serviceEnded, .noRoute:
            // "다시 검색하기" 실동작(Phase 17) — 도착지 슬롯을 비우고 포커스를 넘겨
            // 즉시 재검색이 가능하게 한다. 출발지는 유지(대개 현재 위치).
            arrival = nil
            var newFields = fields
            newFields.arrivalText = ""
            newFields.activeField = .arrival
            fields = newFields
            showRecent()
        case .failed:
            showRecent()
        default:
            break
        }
    }

    func didTapBack() {
        onBackRequested?()
    }

    // MARK: - 내부 전이

    /// 출발지 기본값 = 현재 위치. 실패·권한 거부는 조용히 무시한다 (권한 안내 UX는 홈 담당).
    private func prefillDepartureWithCurrentLocation() {
        guard let useCase = getCurrentLocationUseCase else { return }
        locationTask = Task { [weak self] in
            guard let coordinate = try? await useCase.execute() else { return }
            guard !Task.isCancelled, let self else { return }
            self.currentCoordinate = coordinate
            // 사용자가 이미 출발지를 만졌다면 덮어쓰지 않는다.
            guard self.departure == nil, self.fields.departureText.isEmpty else { return }
            self.departure = Place(name: "현재 위치", address: "", coordinate: coordinate)
            var newFields = self.fields
            newFields.departureText = "현재 위치"
            newFields.activeField = .arrival
            self.fields = newFields
            // 위치가 늦게 도착해 도착지가 먼저 확정된 경우를 마감한다.
            if self.arrival != nil { self.searchRoutes() }
        }
    }

    private func confirm(_ place: Place, in field: Field) {
        searchTask?.cancel()
        saveTask = Task { [weak self] in
            guard let useCase = self?.recentSearchesUseCase else { return }
            try? await useCase.save(place)
        }

        var newFields = fields
        switch field {
        case .departure:
            departure = place
            newFields.departureText = place.name
        case .arrival:
            arrival = place
            newFields.arrivalText = place.name
        }

        if departure != nil, arrival != nil {
            fields = newFields
            searchRoutes()
        } else {
            newFields.activeField = (field == .departure) ? .arrival : .departure
            fields = newFields
            showRecent()
        }
    }

    private func searchRoutes() {
        guard let start = departure?.coordinate, let end = arrival?.coordinate else { return }
        searchTask?.cancel()
        recentTask?.cancel()
        routeTask?.cancel()
        state = .loadingRoutes
        routeTask = Task { [weak self] in
            guard let useCase = self?.searchLastRoutesUseCase else { return }
            do {
                let result = try await useCase.execute(start: start, end: end)
                guard !Task.isCancelled else { return }
                switch result {
                case let .available(routes) where !routes.isEmpty:
                    guard let self else { return }
                    self.availableRoutes = routes
                    self.isExpanded = false
                    self.state = .routes(
                        RouteResultsViewData(entities: routes, isExpanded: false, now: self.now())
                    )
                case .available:
                    // 정규화가 놓친 빈 목록 방어.
                    self?.state = .noRoute
                case .serviceEnded:
                    self?.state = .serviceEnded
                case .noRoute:
                    self?.state = .noRoute
                }
            } catch {
                guard !Task.isCancelled else { return }
                self?.state = .failed(message: "막차를 찾지 못했어요")
            }
        }
    }

    private func showRecent() {
        recentTask?.cancel()
        recentTask = Task { [weak self] in
            guard let useCase = self?.recentSearchesUseCase else { return }
            // 최근 검색 로드 실패는 빈 목록으로 무해화한다.
            let places = (try? await useCase.fetch()) ?? []
            guard !Task.isCancelled else { return }
            self?.listedPlaces = places
            self?.state = .recent(places.map(PlaceViewData.init(entity:)))
        }
    }
}
