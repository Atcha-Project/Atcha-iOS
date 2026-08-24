import CoreCoordinator
import Domain
import HomeFeature
import HomeFeatureInterface
import SearchFeatureInterface
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var homeCoordinator: (any Coordinator)?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let navigationController = UINavigationController()
        let container = HomeDIContainer(
            getCurrentLocationUseCase: PreviewGetCurrentLocationUseCase(),
            reverseGeocodeUseCase: PreviewReverseGeocodeUseCase(),
            registerAlarmUseCase: PreviewRegisterAlarmUseCase(),
            cancelAlarmUseCase: PreviewCancelAlarmUseCase(),
            observeAlarmUseCase: PreviewObserveAlarmUseCase(),
            observeAlarmChangeUseCase: PreviewObserveAlarmChangeUseCase(),
            requestAlarmSyncUseCase: PreviewRequestAlarmSyncUseCase(),
            getLastRouteDetailUseCase: PreviewGetLastRouteDetailUseCase(),
            searchLastRoutesUseCase: PreviewSearchLastRoutesUseCase(),
            recentSearchesUseCase: PreviewRecentSearchesUseCase(),
            searchCoordinatorBuildable: PreviewSearchCoordinatorBuildable()
        )
        let coordinator = container.makeHomeCoordinator(navigationController: navigationController)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        homeCoordinator = coordinator
        coordinator.start()
    }
}

// Example apps wire stub use cases — no Data/network dependency.

struct PreviewGetCurrentLocationUseCase: GetCurrentLocationUseCase {
    func execute() async throws -> Coordinate {
        try? await Task.sleep(for: .milliseconds(400))
        return Coordinate(latitude: 37.4979, longitude: 127.0276)
    }
}

struct PreviewReverseGeocodeUseCase: ReverseGeocodeUseCase {
    func execute(coordinate: Coordinate) async throws -> Place {
        try? await Task.sleep(for: .milliseconds(200))
        return Place(name: "강남역", address: "서울 강남구 강남대로 396", coordinate: coordinate)
    }
}

struct PreviewRegisterAlarmUseCase: RegisterAlarmUseCase {
    @discardableResult
    func execute(route: LastRoute) async throws -> LocalNotificationAuthorizationOutcome {
        try? await Task.sleep(for: .milliseconds(500))
        return .alreadySettled
    }
}

struct PreviewCancelAlarmUseCase: CancelAlarmUseCase {
    func execute(lastRouteId: String) async throws {
        try? await Task.sleep(for: .milliseconds(300))
    }
}

/// 등록된 알람이 없는 서버 상태를 흉내 낸다 — 동기화 이벤트가 오지 않으므로 화면을 건드리지 않는다.
struct PreviewObserveAlarmUseCase: ObserveAlarmUseCase {
    func execute() -> AsyncStream<AlarmSyncUpdate> {
        AsyncStream { _ in }
    }
}

/// 수동 갱신(pull-to-refresh) 스텁 — 잠깐 도는 스피너만 흉내 낸다(결과 스트림 없음).
struct PreviewRequestAlarmSyncUseCase: RequestAlarmSyncUseCase {
    func execute() async {
        try? await Task.sleep(for: .milliseconds(600))
    }
}

/// 막차 변경 판정이 없는 상태를 흉내 낸다 — 토스트·배너 강조는 발생하지 않는다.
struct PreviewObserveAlarmChangeUseCase: ObserveAlarmChangeUseCase {
    func execute() -> AsyncStream<AlarmChangeVerdict> {
        AsyncStream { _ in }
    }
}

/// 재실행 카드 복원 경로 스텁 — 동기화 이벤트가 없어 호출되지 않지만, 호출돼도
/// canned 경로를 돌려줘 플로우가 성립한다.
struct PreviewGetLastRouteDetailUseCase: GetLastRouteDetailUseCase {
    func execute(routeId: String) async throws -> LastRoute {
        try? await Task.sleep(for: .milliseconds(300))
        return PreviewSearchCoordinator.makeCannedRoute()
    }
}

/// 원탭 칩 재검색 스텁(Phase 18) — canned 경로 1건을 돌려줘 칩 탭 → 카드 시연이 성립한다.
struct PreviewSearchLastRoutesUseCase: SearchLastRoutesUseCase {
    func execute(start: Coordinate, end: Coordinate) async throws -> LastRouteSearchResult {
        try? await Task.sleep(for: .milliseconds(400))
        return .available([PreviewSearchCoordinator.makeCannedRoute()])
    }
}

/// 최근 검색 스텁(Phase 18) — canned 1건으로 칩이 즉시 표출된다. save/remove는 no-op.
struct PreviewRecentSearchesUseCase: RecentSearchesUseCase {
    func fetch() async throws -> [Place] {
        [PreviewSearchCoordinator.makeCannedArrival()]
    }

    func save(_ place: Place) async throws {}
    func remove(_ place: Place) async throws {}
}

/// 검색 플로우 스텁: 화면 전환 없이 canned 경로를 즉시 반환한다.
/// 실제 검색 UX 시연은 SearchFeatureExample이 담당한다.
struct PreviewSearchCoordinatorBuildable: SearchCoordinatorBuildable {
    func makeSearchCoordinator(
        navigationController: UINavigationController,
        initialField: SearchEntryField,
        onRouteSelected: @escaping (LastRoute, Place) -> Void
    ) -> any Coordinator {
        PreviewSearchCoordinator(onRouteSelected: onRouteSelected)
    }
}

final class PreviewSearchCoordinator: Coordinator {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?

    private let onRouteSelected: (LastRoute, Place) -> Void

    init(onRouteSelected: @escaping (LastRoute, Place) -> Void) {
        self.onRouteSelected = onRouteSelected
    }

    func start() {
        onRouteSelected(Self.makeCannedRoute(), Self.makeCannedArrival())
        finish()
    }

    // 도착지 필드 바인딩(Phase 17) 시연용 — canned 경로의 하차지와 같은 동네.
    nonisolated static func makeCannedArrival() -> Place {
        Place(
            name: "구로디지털단지역",
            address: "서울 구로구 도림천로 486",
            coordinate: Coordinate(latitude: 37.4853, longitude: 126.9015)
        )
    }

    // nonisolated: 상세 재조회 스텁(nonisolated async)에서도 공유한다.
    nonisolated static func makeCannedRoute() -> LastRoute {
        let departure = Date().addingTimeInterval(42 * 60)
        return LastRoute(
            id: "preview-route",
            departureTime: departure,
            totalTime: 2940,
            totalWalkTime: 480,
            transferCount: 1,
            totalDistance: 14200,
            totalWalkDistance: 700,
            legs: [
                TransportLeg(
                    mode: .subway,
                    sectionTime: 1500,
                    distance: 9000,
                    departureTime: departure,
                    routeName: "2호선",
                    lineType: "2",
                    start: RoutePoint(name: "강남역", coordinate: Coordinate(latitude: 37.4979, longitude: 127.0276)),
                    end: RoutePoint(name: "당산역", coordinate: Coordinate(latitude: 37.5343, longitude: 126.9024)),
                    subwayFinalStation: "홍대입구행",
                    subwayDirection: "외선",
                    isExpressSubway: false,
                    isLastSubway: true
                ),
                TransportLeg(
                    mode: .bus,
                    sectionTime: 960,
                    distance: 4500,
                    departureTime: nil,
                    routeName: "간선:6411",
                    lineType: "11",
                    start: RoutePoint(name: "당산역", coordinate: Coordinate(latitude: 37.5343, longitude: 126.9024)),
                    end: RoutePoint(name: "구로디지털단지", coordinate: Coordinate(latitude: 37.4853, longitude: 126.9015)),
                    subwayFinalStation: nil,
                    subwayDirection: nil,
                    isExpressSubway: false,
                    isLastSubway: false
                ),
            ]
        )
    }
}
