import Domain
import Foundation

// Convention: every ViewModel in the codebase is @MainActor.
@MainActor
final class HomeViewModel {
    enum DepartureState: Equatable {
        case loading
        /// 역지오코딩된 현재 위치 라벨.
        case current(name: String)
        /// 위치를 쓸 수 없어 검색으로 출발지를 정해야 하는 상태.
        case needsSearch(deniedPermission: Bool)
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

    struct State: Equatable {
        var departure: DepartureState = .loading
        var routeCard: RouteCardViewData?
        var banner: BannerViewData?
        var isAlarmBusy = false
        var alarmButton: AlarmButtonMode = .hidden
    }

    /// 재방출되면 안 되는 원샷 안내 — 상태와 분리한다.
    enum ToastEvent: Equatable {
        case locationPermissionNeeded
        case alarmPermissionNeeded
        case alarmRegisterFailed
        case alarmCancelFailed
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
    /// Set by the Coordinator: 검색 플로우를 열고, 선택 경로를 reply 클로저로 돌려받는다.
    var onSearchRequested: ((_ onRouteSelected: @escaping (LastRoute) -> Void) -> Void)?

    private(set) var state = State() {
        didSet { if state != oldValue { onStateChange?(state) } }
    }

    private let getCurrentLocationUseCase: any GetCurrentLocationUseCase
    private let reverseGeocodeUseCase: any ReverseGeocodeUseCase
    private let registerAlarmUseCase: any RegisterAlarmUseCase
    private let cancelAlarmUseCase: any CancelAlarmUseCase
    private let observeAlarmUseCase: any ObserveAlarmUseCase
    private let observeAlarmChangeUseCase: any ObserveAlarmChangeUseCase
    private let now: @Sendable () -> Date
    private let bannerTickInterval: Duration

    private var selectedRoute: LastRoute?
    /// 서버에 알람이 등록된 경로 id — 해제 버튼·동기화 복원의 기준.
    private var registeredRouteId: String?
    private var locationTask: Task<Void, Never>?
    private var alarmTask: Task<Void, Never>?
    private var observeTask: Task<Void, Never>?
    private var changeTask: Task<Void, Never>?
    private var bannerTask: Task<Void, Never>?

    init(
        getCurrentLocationUseCase: any GetCurrentLocationUseCase,
        reverseGeocodeUseCase: any ReverseGeocodeUseCase,
        registerAlarmUseCase: any RegisterAlarmUseCase,
        cancelAlarmUseCase: any CancelAlarmUseCase,
        observeAlarmUseCase: any ObserveAlarmUseCase,
        observeAlarmChangeUseCase: any ObserveAlarmChangeUseCase,
        now: @escaping @Sendable () -> Date = { Date() },
        bannerTickInterval: Duration = .seconds(60)
    ) {
        self.getCurrentLocationUseCase = getCurrentLocationUseCase
        self.reverseGeocodeUseCase = reverseGeocodeUseCase
        self.registerAlarmUseCase = registerAlarmUseCase
        self.cancelAlarmUseCase = cancelAlarmUseCase
        self.observeAlarmUseCase = observeAlarmUseCase
        self.observeAlarmChangeUseCase = observeAlarmChangeUseCase
        self.now = now
        self.bannerTickInterval = bannerTickInterval
    }

    deinit {
        locationTask?.cancel()
        alarmTask?.cancel()
        observeTask?.cancel()
        changeTask?.cancel()
        bannerTask?.cancel()
    }

    // MARK: - 입력

    func viewDidLoad() {
        loadCurrentLocation()
        observeAlarmUpdates()
        observeAlarmChanges()
    }

    /// 출발지/도착지 어느 필드를 탭해도 동일하게 검색 플로우로 진입한다.
    func searchFieldTapped() {
        onSearchRequested? { [weak self] route in
            self?.routeSelected(route)
        }
    }

    func routeSelected(_ route: LastRoute) {
        selectedRoute = route
        var newState = state
        newState.routeCard = RouteCardViewData(entity: route)
        // 새 경로 선택 = 기존 배너는 더 이상 유효하지 않다 (재등록 전까지 숨김).
        newState.banner = nil
        newState.alarmButton = Self.alarmButtonMode(
            selectedRouteId: route.id,
            registeredRouteId: registeredRouteId
        )
        state = newState
        bannerTask?.cancel()
    }

    func registerAlarmTapped() {
        guard let route = selectedRoute, !state.isAlarmBusy else { return }
        alarmTask?.cancel()
        state.isAlarmBusy = true
        // [weak self]: the in-flight task must not keep the ViewModel alive.
        alarmTask = Task { [weak self] in
            guard let useCase = self?.registerAlarmUseCase else { return }
            do {
                try await useCase.execute(route: route)
                guard !Task.isCancelled else { return }
                self?.registeredRouteId = route.id
                self?.state.isAlarmBusy = false
                self?.refreshAlarmButton()
                self?.startBannerTimer(departure: route.departureTime)
            } catch AlarmError.permissionDenied {
                guard !Task.isCancelled else { return }
                self?.state.isAlarmBusy = false
                self?.onToast?(.alarmPermissionNeeded)
            } catch {
                guard !Task.isCancelled else { return }
                self?.state.isAlarmBusy = false
                self?.onToast?(.alarmRegisterFailed)
            }
        }
    }

    func cancelAlarmTapped() {
        guard let routeId = registeredRouteId, !state.isAlarmBusy else { return }
        alarmTask?.cancel()
        state.isAlarmBusy = true
        alarmTask = Task { [weak self] in
            guard let useCase = self?.cancelAlarmUseCase else { return }
            do {
                try await useCase.execute(lastRouteId: routeId)
                guard !Task.isCancelled, let self else { return }
                self.bannerTask?.cancel()
                self.registeredRouteId = nil
                var newState = self.state
                newState.banner = nil
                newState.isAlarmBusy = false
                newState.alarmButton = Self.alarmButtonMode(
                    selectedRouteId: self.selectedRoute?.id,
                    registeredRouteId: nil
                )
                self.state = newState
            } catch {
                guard !Task.isCancelled else { return }
                self?.state.isAlarmBusy = false
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
            guard let stream = self?.observeAlarmUseCase.execute() else { return }
            for await info in stream {
                guard !Task.isCancelled else { return }
                self?.alarmSynced(info)
            }
        }
    }

    private func alarmSynced(_ info: AlarmInfo) {
        registeredRouteId = info.lastRouteId
        refreshAlarmButton()
        // 유예(출발+60초)가 지난 시각으로는 배너를 (재)시작하지 않는다 — 지난 막차의
        // 복원은 오정보이고, 못 탐(actionable=false) 판정이 고정한 실패 배너를 후속
        // 동기화가 덮어쓰는 일도 이 가드가 막는다. 유예 안이면 시작한다 — 발화~유예
        // 창의 "지금 출발하세요"(2단계)도 동기화 복원 대상이다.
        if let departure = info.departureTime,
           !AlarmTiming.isSessionExpired(departureTime: departure, now: now()) {
            startBannerTimer(departure: departure)
        }
    }

    /// 포그라운드 인앱 채널: 앱이 떠 있을 때의 변경 판정은 LA alert 대신 여기서 소비한다.
    /// 배너의 시각·긴급도 자체는 info 스트림(alarmSynced)이 이미 갱신하므로, 이 스트림은
    /// 원샷 안내(당겨짐·못 탐·운행 종료)와 실패·종료 시의 배너 정리만 담당한다.
    private func observeAlarmChanges() {
        changeTask?.cancel()
        changeTask = Task { [weak self] in
            guard let stream = self?.observeAlarmChangeUseCase.execute() else { return }
            for await verdict in stream {
                guard !Task.isCancelled else { return }
                self?.alarmChanged(verdict)
            }
        }
    }

    private func alarmChanged(_ verdict: AlarmChangeVerdict) {
        switch verdict {
        case let .advanced(by: interval, actionable: true):
            // 반올림하되 최소 1분 — "0분 당겨졌어요"는 말이 안 된다.
            let minutes = max(1, Int((interval / 60).rounded()))
            onToast?(.lastTrainAdvanced(minutes: minutes))
        case .advanced(by: _, actionable: false):
            // 이미 못 타는 앞당김 — 카운트다운을 멈추고 배너를 실패 문구로 고정한다.
            // 알람·LA·서버 정리는 App(AlarmSyncService)·Domain 몫이고, 홈은 표출만 바꾼다.
            // 긴급 스타일(imminent)은 유지 — 텍스트만 실패 문구로 교체된 같은 배너다.
            bannerTask?.cancel()
            state.banner = BannerViewData(text: "막차가 지나갔어요", urgency: .imminent)
            onToast?(.lastTrainMissed)
        case .sessionEnded:
            // 운행 종료·경로 소멸 — 알람 세션이 사라졌으므로 배너·버튼·등록 기록을 전부
            // 정리한다. 직전 info 이벤트(alarmSynced)가 남긴 죽은 registeredRouteId도
            // 여기서 지워진다. LA final state 종료·알람 취소는 App/Domain 경로의 몫.
            bannerTask?.cancel()
            registeredRouteId = nil
            var newState = state
            newState.banner = nil
            newState.alarmButton = Self.alarmButtonMode(
                selectedRouteId: selectedRoute?.id,
                registeredRouteId: nil
            )
            state = newState
            onToast?(.lastTrainServiceEnded)
        case .delayed, .unchanged:
            // 정책: 늦춰짐은 조용한 업데이트 — 배너는 info 스트림이 갱신하고 토스트는 없다.
            break
        }
    }

    private func loadCurrentLocation() {
        locationTask?.cancel()
        state.departure = .loading
        locationTask = Task { [weak self] in
            do {
                guard let locationUseCase = self?.getCurrentLocationUseCase else { return }
                let coordinate = try await locationUseCase.execute()
                guard !Task.isCancelled,
                      let geocodeUseCase = self?.reverseGeocodeUseCase else { return }
                let place = try await geocodeUseCase.execute(coordinate: coordinate)
                guard !Task.isCancelled else { return }
                self?.state.departure = .current(name: place.name)
            } catch LocationError.permissionDenied {
                guard !Task.isCancelled else { return }
                self?.state.departure = .needsSearch(deniedPermission: true)
                self?.onToast?(.locationPermissionNeeded)
            } catch {
                guard !Task.isCancelled else { return }
                // 역지오코딩 실패 포함 — 검색으로 출발지를 정하면 된다.
                self?.state.departure = .needsSearch(deniedPermission: false)
            }
        }
    }

    private func refreshAlarmButton() {
        state.alarmButton = Self.alarmButtonMode(
            selectedRouteId: selectedRoute?.id,
            registeredRouteId: registeredRouteId
        )
    }

    private func startBannerTimer(departure: Date) {
        bannerTask?.cancel()
        // 매 틱 departure 기준으로 재계산 — 누적 드리프트가 없다.
        bannerTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let now = self?.now() else { return }
                guard let banner = Self.makeBanner(departure: departure, now: now) else {
                    // 유예 경과(3단계) — 배너·버튼을 내리고 카드를 "지난 막차"로 전환,
                    // 틱 종료. 알람·LA·서버 정리는 App(AlarmSyncService)의 wake 판정 몫.
                    self?.sessionExpired(departure: departure)
                    return
                }
                self?.state.banner = banner
                // sleep 동안 self를 잡지 않는다 — deinit cancel이 즉시 먹혀야 한다.
                guard let interval = self?.bannerTickInterval else { return }
                try? await Task.sleep(for: interval)
            }
        }
    }

    /// 유예 경과(클라 자체 만료, Phase 13) — 지나간 막차를 "탈 수 있다"고 보여주는
    /// 서피스를 전부 내린다. 카드가 없으면(재실행 복원 상태) 배너·버튼 정리만 남는다.
    private func sessionExpired(departure: Date) {
        registeredRouteId = nil
        selectedRoute = nil
        var newState = state
        newState.banner = nil
        newState.routeCard = newState.routeCard?.asPastTrain(departure: departure)
        newState.alarmButton = .hidden
        state = newState
    }

    // MARK: - 순수 계산

    nonisolated static func alarmButtonMode(
        selectedRouteId: String?,
        registeredRouteId: String?
    ) -> AlarmButtonMode {
        if let selectedRouteId {
            // 선택한 카드가 등록된 경로면 해제, 아니면 (재)등록.
            return selectedRouteId == registeredRouteId ? .cancel : .register
        }
        // 카드 없이 등록만 남은 상태(재실행 복원) — 해제만 가능하다.
        return registeredRouteId == nil ? .hidden : .cancel
    }

    nonisolated static func minutesUntil(departure: Date, now: Date) -> Int {
        max(0, Int(ceil(departure.timeIntervalSince(now) / 60)))
    }

    /// 카운트다운·긴급도 모두 **버퍼 포함 알람 발화 시각**(AlarmTiming) 기준 — LA와 기준을
    /// 통일한다(이중 시각 금지). 그래서 문구도 "막차 출발까지"가 아니라 사용자가 출발해야
    /// 할 시각 기준의 "출발까지"다.
    ///
    /// Phase 13 배너 3단계 전이:
    /// 1) now < 알람 시각: "출발까지 N분"
    /// 2) 알람 시각 ≤ now < 출발+유예: "지금 출발하세요" (imminent 고정 — "출발까지 0분" 제거)
    /// 3) 유예 경과: nil — 호출자가 배너를 내리고 카드를 "지난 막차"로 전환할 시점.
    nonisolated static func makeBanner(departure: Date, now: Date) -> BannerViewData? {
        guard !AlarmTiming.isSessionExpired(departureTime: departure, now: now) else {
            return nil
        }
        let alarmDate = AlarmTiming.alarmFireDate(departureTime: departure)
        guard now < alarmDate else {
            return BannerViewData(text: "지금 출발하세요", urgency: .imminent)
        }
        return BannerViewData(
            text: "출발까지 \(minutesUntil(departure: alarmDate, now: now))분",
            urgency: LastTrainUrgency.forTimeRemaining(alarmDate.timeIntervalSince(now))
        )
    }
}
