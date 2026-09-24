import Domain
import Foundation
import SearchFeatureInterface

// Convention: every ViewModel in the codebase is @MainActor.
@MainActor
final class HomeViewModel {
    enum DepartureState: Equatable {
        case loading
        /// 역지오코딩된 현재 위치 라벨.
        case current(name: String)
        /// 위치를 쓸 수 없어 검색으로 출발지를 정해야 하는 상태.
        /// 실패 사유는 ToastEvent가 나른다(Phase 17) — 표시 상태는 사유와 무관하다.
        case needsSearch
    }

    nonisolated struct BannerViewData: Equatable {
        let text: String
        /// 긴급도 3단계(여유/주의/임박) — Domain 기준을 그대로 쓴다. LA와 같은 척도여야
        /// 배너·잠금화면이 다른 색을 보여주는 일이 없다.
        let urgency: LastTrainUrgency
    }

    /// 알람 버튼 슬롯의 표출 모드 — 선택 경로·등록 상태의 순수 함수로 계산한다.
    enum AlarmButtonMode: Equatable {
        case hidden
        case register
        case cancel
    }

    /// 화면 상태 전부. **저장 필드는 4개뿐**이고 나머지는 전부 파생이다.
    ///
    /// 예전에는 저장 필드가 10개였고 표현 가능 조합이 1,536개였다. 실제로 합법인 것은
    /// 그중 일부라, "등록 없는 배너"·"카드 없는 selectedRouteId" 같은 불법 조합을
    /// 메서드가 손으로 막고 있었다. 축을 묶어 **표현 자체를 불가능하게** 만든다.
    ///
    /// 읽기 이름(`routeCard`·`banner`·`alarmButton` …)은 그대로 둔다 — 저장 구조를
    /// 고치는 일이 VC·테스트 전면 개명으로 번지지 않게 하기 위한 의도적 선택이다.
    struct State: Equatable {
        var departure: DepartureState = .loading
        /// 도착지 필드 표시값(Phase 17) — 선택 경로의 도착지명. nil이면 placeholder.
        /// 재실행 복원 경로는 도착지 명칭 원천이 없어 채우지 않는다(결정사항 — 수용).
        var arrivalText: String?
        /// 최근 경로 원탭 칩(Phase 18). 원천은 RecentSearchRepository 하나뿐.
        var chip: HomeChipState = .hidden
        /// 카드·등록·배너·확인 시각·진행 중 여부를 한 타입에 가둔다.
        var session: HomeSessionState = .empty

        // MARK: 파생 — 저장하지 않는다.

        var recentRouteChipText: String? { chip.text }
        var isChipBusy: Bool { chip.isBusy }
        var routeCard: RouteCardViewData? { session.card?.view }
        var banner: BannerViewData? { session.registration?.banner }
        var isAlarmBusy: Bool { session.isBusy }
        /// 화면에 떠 있는 카드의 경로 id.
        var selectedRouteId: String? { session.card?.routeId }
        /// 서버에 알람이 등록된 경로 id.
        var registeredRouteId: String? { session.registration?.routeId }
        /// 세션이 마지막으로 서버로 확인된 시각. 스트림의 checkedAt·등록 성공 시각만이
        /// 원천이다(수신 시각으로 찍지 않는다 — 시딩 복원값의 둔갑 방지).
        var syncedAt: Date? { session.registration?.syncedAt }

        var alarmButton: AlarmButtonMode { session.alarmButton }

        /// 신선도 스탬프 "HH:mm 확인 기준" — 배너 보조 라인·카드 푸터 공용 단일 소스.
        /// sync 무음 실패 시 낡은 시각을 그대로 유지하는 것이 실패의 정직한 표면이다(원칙 3).
        var freshnessText: String? {
            HomeViewModel.freshnessText(
                checkedAt: syncedAt, isRegistered: registeredRouteId != nil
            )
        }
    }

    /// 재방출되면 안 되는 원샷 안내 — 상태와 분리한다.
    enum ToastEvent: Equatable {
        case locationPermissionNeeded
        /// 기기 전역 위치 서비스 OFF(Phase 17) — 앱 권한이 아니라 시스템 설정의 문제.
        case locationServicesDisabled
        /// 스크린타임·MDM 제약(Phase 17) — 설정으로 못 푼다. "설정으로 이동" 안내 금지.
        case locationRestricted
        /// 칩 원탭 재검색(Phase 18)의 위치 일시 실패 — 명시적 탭에 무음은 없다.
        case chipLocationUnavailable
        /// 칩 재검색 자체 실패(Phase 18) — 재시도 유도. 카드·필드는 무변경이 원칙.
        case chipSearchFailed
        /// 칩 재검색 결과 오늘 막차 종료(Phase 18) — 검색 빈 상태 제목과 같은 어휘.
        case chipServiceEnded
        /// 칩 재검색 결과 경로 없음(Phase 18).
        case chipNoRoute
        /// 칩 재검색 결과 서비스 지역 밖 — 서버 TRS_012.
        case chipOutOfServiceRegion
        case alarmPermissionNeeded
        case alarmRegisterFailed
        case alarmCancelFailed
        /// 발화 시각이 이미 과거인 경로의 등록 시도(사전 가드, Phase 14) — 서버 등록 전에 차단됐다.
        case alarmTooLate
        /// 알림 권한이 이번 등록에서 최초 요청됐고 거부됨(Phase 15) — 폴백 노티를 잃었다는
        /// 1회 안내. 요청이 평생 1회(어댑터 가드)라 이 안내도 구조적으로 최대 1회다.
        case notificationPermissionDenied
        /// 포그라운드 인앱 채널: 막차가 당겨졌다는 판정 — VC가 토스트 + 배너 강조로 표출한다.
        case lastTrainAdvanced(minutes: Int)
        /// 이미 못 타는 앞당김(actionable=false) — 배너는 실패 문구로 고정되고 원샷 안내만 나간다.
        case lastTrainMissed
        /// 운행 종료·경로 소멸(sessionEnded) — 배너·버튼 정리를 마쳤다는 원샷 안내.
        case lastTrainServiceEnded
    }

    /// Set by the ViewController; always invoked on the main actor.
    var onStateChange: ((State) -> Void)?
    var onToast: ((ToastEvent) -> Void)?
    /// pull-to-refresh 종료 훅(Phase 16) — 성공/실패 불문 동기화가 끝나면 불린다
    /// (VC가 refreshControl.endRefreshing). 실패는 무음 — 결과 표출은 스트림·스탬프 몫.
    var onManualSyncFinished: (() -> Void)?
    /// Set by the Coordinator: 검색 플로우를 열고, 선택 경로·도착지를 reply 클로저로
    /// 돌려받는다. initialField = 탭한 필드가 그대로 진입 슬롯이 된다(Phase 17).
    var onSearchRequested: ((
        _ initialField: SearchEntryField,
        _ onRouteSelected: @escaping (LastRoute, Place) -> Void
    ) -> Void)?
    /// Set by the Coordinator: 설정 플로우 진입(홈 상단 톱니바퀴).
    var onSettingsRequested: (() -> Void)?

    private(set) var state = State() {
        didSet { if state != oldValue { onStateChange?(state) } }
    }

    private let locationService: any LocationService
    private let placeRepository: any PlaceRepository
    private let registerAlarmUseCase: any RegisterAlarmUseCase
    private let cancelAlarmUseCase: any CancelAlarmUseCase
    // Domain 포트를 직접 받는다. 이전에는 같은 프로토콜을 한 겹 더 감싼 UseCase를
    // 주입받았는데, 조합도 규칙도 없이 호출만 위임하는 계층이라 이름만 늘렸다.
    private let alarmSyncEvents: any AlarmSyncEvents
    private let alarmChangeEvents: any AlarmChangeEvents
    private let alarmSyncRequesting: any AlarmSyncRequesting
    private let lastRouteRepository: any LastRouteRepository
    private let searchLastRoutesUseCase: any SearchLastRoutesUseCase
    private let recentSearchRepository: any RecentSearchRepository
    private let now: @Sendable () -> Date

    /// 화면에 떠 있는 경로 원본 — 재등록·"지난 막차" 판정이 쓴다. 표시용 id는
    /// `state.session.card`가 들고 있으므로 여기서 손으로 맞출 필요가 없다.
    private var selectedRoute: LastRoute?
    /// 칩의 원본 도착지(Phase 18) — 표시는 문자열(State), 재검색은 이 Place가 한다.
    private var chipPlace: Place?
    /// 서버에 알람이 등록된 경로 id — 해제 버튼·동기화 복원의 기준.
    private var locationTask: Task<Void, Never>?
    private var alarmTask: Task<Void, Never>?
    private var observeTask: Task<Void, Never>?
    private var changeTask: Task<Void, Never>?
    private var restoreCardTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var chipTask: Task<Void, Never>?
    // 승격 저장은 재조회와 분리 보관 — 재조회가 저장을 cancel하면 안 된다(검색 VM saveTask 선례).
    private var chipSaveTask: Task<Void, Never>?
    private var chipSearchTask: Task<Void, Never>?

    init(
        locationService: any LocationService,
        placeRepository: any PlaceRepository,
        registerAlarmUseCase: any RegisterAlarmUseCase,
        cancelAlarmUseCase: any CancelAlarmUseCase,
        alarmSyncEvents: any AlarmSyncEvents,
        alarmChangeEvents: any AlarmChangeEvents,
        alarmSyncRequesting: any AlarmSyncRequesting,
        lastRouteRepository: any LastRouteRepository,
        searchLastRoutesUseCase: any SearchLastRoutesUseCase,
        recentSearchRepository: any RecentSearchRepository,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.locationService = locationService
        self.placeRepository = placeRepository
        self.registerAlarmUseCase = registerAlarmUseCase
        self.cancelAlarmUseCase = cancelAlarmUseCase
        self.alarmSyncEvents = alarmSyncEvents
        self.alarmChangeEvents = alarmChangeEvents
        self.alarmSyncRequesting = alarmSyncRequesting
        self.lastRouteRepository = lastRouteRepository
        self.searchLastRoutesUseCase = searchLastRoutesUseCase
        self.recentSearchRepository = recentSearchRepository
        self.now = now
    }

    deinit {
        locationTask?.cancel()
        alarmTask?.cancel()
        observeTask?.cancel()
        changeTask?.cancel()
        restoreCardTask?.cancel()
        refreshTask?.cancel()
        chipTask?.cancel()
        chipSaveTask?.cancel()
        chipSearchTask?.cancel()
    }

    // MARK: - 입력

    func viewDidLoad() {
        loadCurrentLocation()
        observeAlarmUpdates()
        observeAlarmChanges()
        refreshChip()
    }

    /// 홈 재노출(Phase 18) — 검색 화면을 다녀오며 바뀐 최근 검색(삭제 포함)을 칩에 반영한다.
    func viewWillAppear() {
        refreshChip()
    }

    /// 설정을 다녀온 뒤(didBecomeActive) 위치 권한 회복을 재확인한다(Phase 15).
    /// `needsSearch`일 때만 — `.loading`/`.current`면 no-op(권한 팝업 닫힘도 이 노티를
    /// 울리므로 이 가드가 진행 중 재진입·불필요 재조회를 막는다). 재확인 경로는 기존
    /// 표시를 유지한 채 조용히 조회하고 **성공 시에만** 상태를 바꾼다 — 거부 유지 유저의
    /// 매 포그라운드 깜빡임·거부 토스트 재발화(스팸)를 만들지 않는다.
    func didBecomeActive() {
        guard case .needsSearch = state.departure else { return }
        locationTask?.cancel()
        locationTask = Task { [weak self] in
            guard let locationUseCase = self?.locationService,
                  let coordinate = try? await locationUseCase.currentLocation() else { return }
            guard !Task.isCancelled,
                  let geocodeUseCase = self?.placeRepository,
                  let place = try? await geocodeUseCase.reverseGeocode(coordinate)
            else { return }
            guard !Task.isCancelled else { return }
            self?.state.departure = .current(name: place.name)
        }
    }

    /// pull-to-refresh(Phase 16) — 수동 동기화 1회. 진행 중 재진입은 no-op(이중 당김
    /// 무해). 실패는 무음 — 스피너 종료 + 스탬프가 낡은 시각을 유지하는 것이 표면이다.
    func refreshPulled() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            // defer로 비워야 한다 — 아래 취소 가드에서 early return하면 refreshTask가
            // 영원히 non-nil로 남아 진입 가드에 영구히 걸리고(당김 새로고침 영구 잠김)
            // onManualSyncFinished도 불리지 않아 스피너가 멈추지 않는다.
            defer { self?.refreshTask = nil }
            guard let requesting = self?.alarmSyncRequesting else { return }
            await requesting.syncNow()
            guard let self, !Task.isCancelled else { return }
            self.onManualSyncFinished?()
        }
    }

    func settingsTapped() {
        onSettingsRequested?()
    }

    /// 탭한 필드가 그대로 검색 진입 슬롯이 된다(Phase 17) — 도착지 탭이면 도착지부터.
    func searchFieldTapped(_ field: SearchEntryField) {
        onSearchRequested?(field) { [weak self] route, arrival in
            self?.routeSelected(route, arrival: arrival)
        }
    }

    func routeSelected(_ route: LastRoute, arrival: Place) {
        selectedRoute = route
        chipPlace = arrival
        var newState = state
        // 카드 교체 + 배너 무효화가 한 전이다 — 예전에는 두 필드를 따로 고치며
        // `didSet`이 중간 상태를 내보내지 않도록 지역 사본을 돌려야 했다.
        newState.session = state.session.selecting(
            HomeSessionState.Card(routeId: route.id, view: RouteCardViewData(entity: route, now: now()))
        )
        // 도착지 필드를 선택 경로의 도착지명과 정합시킨다(Phase 17) — placeholder 공존 해소.
        newState.arrivalText = arrival.name
        // 칩도 즉시 정합(Phase 18) — fetch를 기다리지 않는다. 방금 확정한 도착지가 최신이다.
        newState.chip = state.chip.withText("→ \(arrival.name)")
        state = newState
        promoteChipDestination(arrival)
    }

    /// 최근 경로 원탭(Phase 18) — 현재 위치 기준 즉시 재검색, 검색 화면 생략.
    /// 성공은 routeSelected로 수렴한다(카드·도착지·배너 무효화·버튼이 검색 복귀와 같은 의미).
    /// 알람 자동 등록은 없다 — 등록은 명시적 버튼 탭만(확정 결정).
    func chipTapped() {
        guard let destination = chipPlace, !state.isChipBusy else { return }
        state.chip = state.chip.busy(true)
        chipSearchTask?.cancel()
        chipSearchTask = Task { [weak self] in
            defer { if let self { self.state.chip = self.state.chip.busy(false) } }

            let start: Coordinate
            do {
                guard let locationUseCase = self?.locationService else { return }
                start = try await locationUseCase.currentLocation()
            } catch let error as LocationError {
                guard !Task.isCancelled else { return }
                // 사유별 안내는 기존 3분기 이벤트 재사용(Phase 17 문구·액션 그대로).
                // 명시적 탭이라 unavailable도 무음일 수 없다 — loadCurrentLocation과의 차이.
                switch error {
                case .permissionDenied: self?.onToast?(.locationPermissionNeeded)
                case .servicesDisabled: self?.onToast?(.locationServicesDisabled)
                case .restricted: self?.onToast?(.locationRestricted)
                case .unavailable: self?.onToast?(.chipLocationUnavailable)
                }
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.onToast?(.chipLocationUnavailable)
                return
            }

            guard !Task.isCancelled,
                  let routesUseCase = self?.searchLastRoutesUseCase else { return }
            do {
                let result = try await routesUseCase.execute(
                    start: start, end: destination.coordinate
                )
                guard !Task.isCancelled, let self else { return }
                switch result {
                case let .available(routes) where !routes.isEmpty:
                    // featured(0번 = 가장 늦은 차)만 원탭의 몫 — 대안 표출은 풀 검색 화면 담당.
                    self.routeSelected(routes[0], arrival: destination)
                case .available:
                    // 정규화가 놓친 빈 목록 방어 (검색 VM 선례).
                    self.onToast?(.chipNoRoute)
                case .serviceEnded:
                    self.onToast?(.chipServiceEnded)
                case .noRoute:
                    self.onToast?(.chipNoRoute)
                case .outOfServiceRegion:
                    self.onToast?(.chipOutOfServiceRegion)
                }
            } catch {
                guard !Task.isCancelled else { return }
                self?.onToast?(.chipSearchFailed)
            }
        }
    }

    func registerAlarmTapped() {
        guard let route = selectedRoute, !state.isAlarmBusy else { return }
        alarmTask?.cancel()
        state.session = state.session.settingBusy(true)
        // [weak self]: the in-flight task must not keep the ViewModel alive.
        alarmTask = Task { [weak self] in
            guard let useCase = self?.registerAlarmUseCase else { return }
            do {
                let followUp = try await useCase.execute(route: route)
                guard !Task.isCancelled, let self else { return }
                // 등록·스탬프·배너·busy 해제가 **한 전이**다. 예전에는 네 필드를 차례로
                // 고쳤고, 그 사이 didSet이 중간 상태를 VC로 내보냈다.
                // 등록 성공 = 서버가 방금 이 값을 확인해줬다 — 스탬프 시작점(Phase 16).
                self.state.session = self.state.session.arming(
                    HomeSessionState.Registration(
                        routeId: route.id,
                        banner: Self.makeBanner(
                            departure: route.departureTime,
                            firstWalkSeconds: route.firstWalkSectionSeconds,
                            now: self.now()
                        ),
                        syncedAt: self.now()
                    ),
                    busy: false
                )
                // 등록은 성공했고 폴백 노티만 잃었다 — 1회 안내(Phase 15). deniedNow는
                // 이번 호출로 최초 요청이 이뤄졌고 거부된 경우뿐이라 재등록 시 반복되지 않는다.
                if followUp == .deniedNow {
                    self.onToast?(.notificationPermissionDenied)
                }
            } catch AlarmError.permissionDenied {
                guard !Task.isCancelled else { return }
                self?.clearAlarmBusy()
                self?.onToast?(.alarmPermissionNeeded)
            } catch AlarmError.tooLate {
                guard !Task.isCancelled else { return }
                self?.clearAlarmBusy()
                self?.onToast?(.alarmTooLate)
            } catch {
                guard !Task.isCancelled else { return }
                self?.clearAlarmBusy()
                self?.onToast?(.alarmRegisterFailed)
            }
        }
    }

    func cancelAlarmTapped() {
        guard let routeId = state.registeredRouteId, !state.isAlarmBusy else { return }
        alarmTask?.cancel()
        state.session = state.session.settingBusy(true)
        alarmTask = Task { [weak self] in
            guard let useCase = self?.cancelAlarmUseCase else { return }
            do {
                try await useCase.execute(lastRouteId: routeId)
                guard !Task.isCancelled, let self else { return }
                // 등록·배너·스탬프·busy가 한꺼번에 사라진다 — 카드는 남는다.
                self.state.session = self.state.session.disarmed()
            } catch {
                guard !Task.isCancelled else { return }
                self?.clearAlarmBusy()
                self?.onToast?(.alarmCancelFailed)
            }
        }
    }

    // MARK: - 내부 전이

    /// 서버 알람 동기화(재조회·재스케줄)는 App의 AlarmSyncService가 앱 시작·포그라운드
    /// 복귀·푸시 수신 3경로를 일원화해 수행한다. 여기서는 성공 결과 스트림만 구독해
    /// 배너·버튼 상태를 갱신한다. 실패는 스트림에 흐르지 않는다 — 상태 유지.
    /// TODO: [미확정] 서버의 "등록된 알람 없음" 표현이 확정되면 그 경우에만
    ///       배너·버튼을 정리하는 이벤트를 추가한다.
    private func observeAlarmUpdates() {
        observeTask?.cancel()
        observeTask = Task { [weak self] in
            guard let stream = self?.alarmSyncEvents.updates() else { return }
            for await update in stream {
                guard !Task.isCancelled else { return }
                self?.alarmSynced(update)
            }
        }
    }

    private func alarmSynced(_ update: AlarmSyncUpdate) {
        let info = update.info
        // 확인 시각은 스트림이 준 값만 쓴다(Phase 16) — 시딩 복원이면 직전 세션의 마지막
        // 확인 시각이고, 그것도 없으면 nil(스탬프 없음). 수신 시각으로 찍지 않는다.
        //
        // 배너는 기존 값을 물려받는다 — 아래 유예 가드가 재시작을 막은 경우에도 이미
        // 떠 있던 배너(특히 "막차가 지나갔어요" 고정 문구)를 지우면 안 된다.
        state.session = state.session.arming(
            HomeSessionState.Registration(
                routeId: info.lastRouteId,
                banner: state.session.registration?.banner,
                syncedAt: update.checkedAt
            ),
            busy: state.session.isBusy
        )
        // 유예(출발+60초)가 지난 시각으로는 배너를 (재)시작하지 않는다 — 지난 막차의
        // 복원은 오정보이고, 못 탐(actionable=false) 판정이 고정한 실패 배너를 후속
        // 동기화가 덮어쓰는 일도 이 가드가 막는다. 유예 안이면 시작한다 — 발화~유예
        // 창의 "지금 출발하세요"(2단계)도 동기화 복원 대상이다.
        if let departure = info.departureTime,
           !AlarmTiming.isSessionExpired(departureTime: departure, now: now()) {
            // 도보 초는 등록 시점 경로에서만 안다 — 같은 경로가 화면에 있으면 그 값,
            // 재실행 복원(카드 없음)이면 상세 재조회가 끝난 뒤 재시작하며 반영한다.
            // 도보 초는 스트림이 싣고 온다 — 세션이 유일한 출처라, 재실행 복원처럼
            // 카드가 없는 상황에서도 정확한 시각을 그린다(이전에는 화면의 경로에서
            // 추측했고 카드가 없으면 버퍼만 적용됐다).
            renderBanner(departure: departure, firstWalkSeconds: update.firstWalkSeconds)
        }
        restoreRouteCardIfNeeded(info)
    }

    /// 재실행 복원 (Phase 14): 알람은 있는데 카드가 없으면 경로 상세를 재조회해 카드를
    /// 복원한다 — "무슨 경로인지 모르는 해제 버튼" 상태 해소. 실패는 현행 폴백(카드 없이
    /// 해제 버튼)으로 조용히 남는다 — 만료 정리가 있어 유령이 오래가지 않는다.
    private func restoreRouteCardIfNeeded(_ info: AlarmInfo) {
        guard state.routeCard == nil, restoreCardTask == nil else { return }
        restoreCardTask = Task { [weak self] in
            defer { self?.restoreCardTask = nil }
            guard let repository = self?.lastRouteRepository else { return }
            guard let route = try? await repository.lastRoute(id: info.lastRouteId) else { return }
            guard !Task.isCancelled, let self else { return }
            // 복원 도중 상태가 변했으면(새 경로 선택·세션 종료) 낡은 복원을 버린다.
            guard self.state.registeredRouteId == info.lastRouteId,
                  self.state.routeCard == nil else { return }
            self.selectedRoute = route
            // 복원 경로는 도착지 명칭 원천이 없다 — arrivalText는 placeholder 유지(Phase 17 수용).
            self.state.session = self.state.session.withCard(
                HomeSessionState.Card(
                    routeId: route.id, view: RouteCardViewData(entity: route, now: self.now())
                )
            )
            // 배너를 도보 반영 기준으로 다시 그린다(등록/refresh/LA와 같은 값 — 이중 시각 금지).
            if let departure = info.departureTime,
               !AlarmTiming.isSessionExpired(departureTime: departure, now: self.now()) {
                self.renderBanner(
                    departure: departure,
                    firstWalkSeconds: route.firstWalkSectionSeconds
                )
            }
        }
    }

    /// 포그라운드 인앱 채널: 앱이 떠 있을 때의 변경 판정은 LA alert 대신 여기서 소비한다.
    /// 배너의 시각·긴급도 자체는 info 스트림(alarmSynced)이 이미 갱신하므로, 이 스트림은
    /// 원샷 안내(당겨짐·못 탐·운행 종료)와 실패·종료 시의 배너 정리만 담당한다.
    private func observeAlarmChanges() {
        changeTask?.cancel()
        changeTask = Task { [weak self] in
            guard let stream = self?.alarmChangeEvents.changes() else { return }
            for await verdict in stream {
                guard !Task.isCancelled else { return }
                self?.alarmChanged(verdict)
            }
        }
    }

    private func alarmChanged(_ verdict: AlarmChangeVerdict) {
        switch verdict {
        case let .advanced(by: interval, actionable: true):
            // 올림 + 최소 1분 — LA 잠금화면 문구(.up)와 같은 분으로 읽혀야 한다(표기 통일,
            // Phase 14). "0분 당겨졌어요"도 자연히 존재하지 않는다.
            let minutes = max(1, Int((interval / 60).rounded(.up)))
            onToast?(.lastTrainAdvanced(minutes: minutes))
        case .advanced(by: _, actionable: false):
            // 이미 못 타는 앞당김 — 카운트다운을 멈추고 배너를 실패 문구로 고정한다.
            // 알람·LA·서버 정리는 App(AlarmSyncService)·Domain 몫이고, 홈은 표출만 바꾼다.
            // 긴급 스타일(imminent)은 유지 — 텍스트만 실패 문구로 교체된 같은 배너다.
            state.session = state.session.withBanner(
                BannerViewData(text: "막차가 지나갔어요", urgency: .imminent)
            )
            onToast?(.lastTrainMissed)
        case .sessionEnded:
            // 운행 종료·경로 소멸 — 알람 세션이 사라졌으므로 배너·버튼·등록 기록을 전부
            // 정리한다. 직전 info 이벤트(alarmSynced)가 남긴 죽은 registeredRouteId도
            // 여기서 지워진다. LA final state 종료·알람 취소는 App/Domain 경로의 몫.
            // 출발 시각이 이미 지났으면 "지난 막차"로 전환한다 — 유예 경과로 인한 로컬
            // 만료가 이 경로로 온다(이전에는 홈의 배너 타이머가 직접 전환했다).
            // 서버발 운행 종료(출발 전 경로 소멸)는 카드를 그대로 둔다 — 지나간 것이
            // 아니라 사라진 것이라 "지난 막차"는 오정보다.
            if let departure = selectedRoute?.departureTime,
               AlarmTiming.isSessionExpired(departureTime: departure, now: now()),
               let card = state.session.card {
                // `.past`는 등록 버튼을 두지 않는다 — 누르면 tooLate로 실패할 뿐이다.
                // 예전에는 버튼이 `selectedRouteId`에서 파생돼, 지역 사본에 id를 함께
                // 지우는 걸 빠뜨리면 지난 막차에 등록 버튼이 남았다(실제 버그).
                selectedRoute = nil
                state.session = .past(
                    HomeSessionState.Card(
                        routeId: card.routeId, view: card.view.asPastTrain(departure: departure)
                    )
                )
            } else {
                state.session = state.session.disarmed()
            }
            onToast?(.lastTrainServiceEnded)
        case .delayed, .unchanged:
            // 정책: 늦춰짐은 조용한 업데이트 — 배너는 info 스트림이 갱신하고 토스트는 없다.
            break
        }
    }

    /// 칩 재조회(Phase 18) — 최근 검색 최신 1건이 칩의 유일한 원천이다(즐겨찾기 아님).
    /// 승격 저장이 진행 중이면 no-op — 저장 전의 낡은 목록으로 되돌리는 경합을 막는다
    /// (저장 완료가 가드를 풀고, 다음 재노출 재조회가 확정 목록을 반영한다).
    private func refreshChip() {
        guard chipSaveTask == nil else { return }
        chipTask?.cancel()
        chipTask = Task { [weak self] in
            guard let repository = self?.recentSearchRepository else { return }
            // 로드 실패는 칩 없음으로 무해화한다 (검색 화면의 최근 목록과 같은 취급).
            let latest = ((try? await repository.recentSearches()) ?? []).first
            guard !Task.isCancelled, let self else { return }
            self.chipPlace = latest
            self.state.chip = self.state.chip.withText(latest.map { "→ \($0.name)" })
        }
    }

    /// 도착지 승격(Phase 18) — 기존 save의 "중복 시 최신 갱신"을 재사용해 확정 도착지를
    /// 최근 검색 최신으로 올린다(새 저장 의미 없음 — 출발지를 나중에 확정한 경우에도
    /// 칩 = 마지막으로 경로를 확정한 도착지가 되게 하는 최소 수단이다). 칩 탭 경로의
    /// 재저장은 이미 최신 1위라 멱등이다.
    private func promoteChipDestination(_ place: Place) {
        chipSaveTask?.cancel()
        chipSaveTask = Task { [weak self] in
            guard let useCase = self?.recentSearchRepository else { return }
            try? await useCase.save(place)
            guard !Task.isCancelled else { return }
            self?.chipSaveTask = nil
        }
    }

    private func loadCurrentLocation() {
        locationTask?.cancel()
        state.departure = .loading
        locationTask = Task { [weak self] in
            do {
                guard let locationUseCase = self?.locationService else { return }
                let coordinate = try await locationUseCase.currentLocation()
                guard !Task.isCancelled,
                      let geocodeUseCase = self?.placeRepository else { return }
                let place = try await geocodeUseCase.reverseGeocode(coordinate)
                guard !Task.isCancelled else { return }
                self?.state.departure = .current(name: place.name)
            } catch let error as LocationError {
                guard !Task.isCancelled else { return }
                self?.state.departure = .needsSearch
                // 사유별 안내 분기(Phase 17) — 회복 경로가 다르다. restricted는 설정으로
                // 못 푸는 제약이라 "설정으로 이동"을 안내하지 않는다(VC 매핑).
                switch error {
                case .permissionDenied: self?.onToast?(.locationPermissionNeeded)
                case .servicesDisabled: self?.onToast?(.locationServicesDisabled)
                case .restricted: self?.onToast?(.locationRestricted)
                case .unavailable: break // 일시 실패 — 검색 유도만, 안내 없음.
                }
            } catch {
                guard !Task.isCancelled else { return }
                // 역지오코딩 실패 포함 — 검색으로 출발지를 정하면 된다.
                self?.state.departure = .needsSearch
            }
        }
    }

    /// 스트림이 세션을 방출할 때마다 배너를 다시 그린다.
    ///
    /// 이전에는 여기서 타이머를 돌리며 유예 경과를 감지하고 **화면이 세션을 끝냈다**
    /// (`sessionExpired`). 이제 틱과 만료 판정은 세션 소유자(Store)가 하고, 홈은
    /// 받은 값을 그리기만 한다 — 만료 시엔 `.sessionEnded` 변경 이벤트가 온다.
    private func renderBanner(departure: Date, firstWalkSeconds: Int?) {
        state.session = state.session.withBanner(
            Self.makeBanner(departure: departure, firstWalkSeconds: firstWalkSeconds, now: now())
        )
    }

    /// 실패 경로의 공통 정리 — busy만 내리고 나머지는 건드리지 않는다.
    private func clearAlarmBusy() {
        state.session = state.session.settingBusy(false)
    }

    // MARK: - 순수 계산

    nonisolated static func minutesUntil(departure: Date, now: Date) -> Int {
        max(0, Int(ceil(departure.timeIntervalSince(now) / 60)))
    }

    /// 카운트다운·긴급도 모두 **도보·버퍼 포함 알람 발화 시각**(AlarmTiming) 기준 — 등록/
    /// refresh/LA와 기준을 통일한다(이중 시각 금지). 그래서 문구도 "막차 출발까지"가
    /// 아니라 사용자가 출발해야 할 시각 기준의 "출발까지"다.
    ///
    /// Phase 13 배너 3단계 전이:
    /// 1) now < 알람 시각: "출발까지 N분"
    /// 2) 알람 시각 ≤ now < 출발+유예: "지금 출발하세요" (imminent 고정 — "출발까지 0분" 제거)
    /// 3) 유예 경과: nil — 호출자가 배너를 내리고 카드를 "지난 막차"로 전환할 시점.
    nonisolated static func makeBanner(
        departure: Date,
        firstWalkSeconds: Int?,
        now: Date
    ) -> BannerViewData? {
        guard !AlarmTiming.isSessionExpired(departureTime: departure, now: now) else {
            return nil
        }
        let alarmDate = AlarmTiming.alarmFireDate(
            departureTime: departure, firstWalkSeconds: firstWalkSeconds
        )
        guard now < alarmDate else {
            return BannerViewData(text: "지금 출발하세요", urgency: .imminent)
        }
        return BannerViewData(
            text: "출발까지 \(minutesUntil(departure: alarmDate, now: now))분",
            urgency: LastTrainUrgency.forTimeRemaining(alarmDate.timeIntervalSince(now))
        )
    }
}
