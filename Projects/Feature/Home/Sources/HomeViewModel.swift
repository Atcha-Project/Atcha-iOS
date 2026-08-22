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

    struct State: Equatable {
        var departure: DepartureState = .loading
        var routeCard: RouteCardViewData?
        var banner: BannerViewData?
        var isRegisteringAlarm = false
    }

    /// 재방출되면 안 되는 원샷 안내 — 상태와 분리한다.
    enum ToastEvent: Equatable {
        case locationPermissionNeeded
        case alarmRegisterFailed
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
    private let now: @Sendable () -> Date
    private let bannerTickInterval: Duration

    private var selectedRoute: LastRoute?
    private var locationTask: Task<Void, Never>?
    private var registerTask: Task<Void, Never>?
    private var bannerTask: Task<Void, Never>?

    init(
        getCurrentLocationUseCase: any GetCurrentLocationUseCase,
        reverseGeocodeUseCase: any ReverseGeocodeUseCase,
        registerAlarmUseCase: any RegisterAlarmUseCase,
        now: @escaping @Sendable () -> Date = { Date() },
        bannerTickInterval: Duration = .seconds(60)
    ) {
        self.getCurrentLocationUseCase = getCurrentLocationUseCase
        self.reverseGeocodeUseCase = reverseGeocodeUseCase
        self.registerAlarmUseCase = registerAlarmUseCase
        self.now = now
        self.bannerTickInterval = bannerTickInterval
    }

    deinit {
        locationTask?.cancel()
        registerTask?.cancel()
        bannerTask?.cancel()
    }

    // MARK: - 입력

    func viewDidLoad() {
        loadCurrentLocation()
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
        state = newState
        bannerTask?.cancel()
    }

    func registerAlarmTapped() {
        guard let route = selectedRoute, !state.isRegisteringAlarm else { return }
        registerTask?.cancel()
        state.isRegisteringAlarm = true
        // [weak self]: the in-flight task must not keep the ViewModel alive.
        registerTask = Task { [weak self] in
            guard let useCase = self?.registerAlarmUseCase else { return }
            do {
                try await useCase.execute(route: route)
                guard !Task.isCancelled else { return }
                self?.state.isRegisteringAlarm = false
                self?.startBannerTimer(departure: route.departureTime)
            } catch {
                guard !Task.isCancelled else { return }
                self?.state.isRegisteringAlarm = false
                self?.onToast?(.alarmRegisterFailed)
            }
        }
    }

    // MARK: - 내부 전이

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

    nonisolated static func minutesUntil(departure: Date, now: Date) -> Int {
        max(0, Int(ceil(departure.timeIntervalSince(now) / 60)))
    }

    nonisolated static func makeBanner(departure: Date, now: Date) -> BannerViewData {
        let minutes = minutesUntil(departure: departure, now: now)
        // 긴박 기준 10분은 디자이너 확정 전 제안값.
        return BannerViewData(text: "막차 출발까지 \(minutes)분", isUrgent: minutes <= 10)
    }
}
