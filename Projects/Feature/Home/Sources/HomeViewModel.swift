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
        let isUrgent: Bool
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
    private let now: @Sendable () -> Date
    private let bannerTickInterval: Duration

    private var selectedRoute: LastRoute?
    /// 서버에 알람이 등록된 경로 id — 해제 버튼·동기화 복원의 기준.
    private var registeredRouteId: String?
    private var locationTask: Task<Void, Never>?
    private var alarmTask: Task<Void, Never>?
    private var observeTask: Task<Void, Never>?
    private var bannerTask: Task<Void, Never>?

    init(
        getCurrentLocationUseCase: any GetCurrentLocationUseCase,
        reverseGeocodeUseCase: any ReverseGeocodeUseCase,
        registerAlarmUseCase: any RegisterAlarmUseCase,
        cancelAlarmUseCase: any CancelAlarmUseCase,
        observeAlarmUseCase: any ObserveAlarmUseCase,
        now: @escaping @Sendable () -> Date = { Date() },
        bannerTickInterval: Duration = .seconds(60)
    ) {
        self.getCurrentLocationUseCase = getCurrentLocationUseCase
        self.reverseGeocodeUseCase = reverseGeocodeUseCase
        self.registerAlarmUseCase = registerAlarmUseCase
        self.cancelAlarmUseCase = cancelAlarmUseCase
        self.observeAlarmUseCase = observeAlarmUseCase
        self.now = now
        self.bannerTickInterval = bannerTickInterval
    }

    deinit {
        locationTask?.cancel()
        alarmTask?.cancel()
        observeTask?.cancel()
        bannerTask?.cancel()
    }

    // MARK: - 입력

    func viewDidLoad() {
        loadCurrentLocation()
        observeAlarmUpdates()
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
        if let departure = info.departureTime {
            startBannerTimer(departure: departure)
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
                self?.state.banner = Self.makeBanner(departure: departure, now: now)
                // sleep 동안 self를 잡지 않는다 — deinit cancel이 즉시 먹혀야 한다.
                guard let interval = self?.bannerTickInterval else { return }
                try? await Task.sleep(for: interval)
            }
        }
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

    nonisolated static func makeBanner(departure: Date, now: Date) -> BannerViewData {
        let minutes = minutesUntil(departure: departure, now: now)
        // 긴박 기준 10분은 디자이너 확정 전 제안값.
        return BannerViewData(text: "막차 출발까지 \(minutes)분", isUrgent: minutes <= 10)
    }
}
