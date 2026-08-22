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
    func execute(route: LastRoute) async throws {
        try? await Task.sleep(for: .milliseconds(500))
    }
}

/// 검색 플로우 스텁: 화면 전환 없이 canned 경로를 즉시 반환한다.
/// 실제 검색 UX 시연은 SearchFeatureExample이 담당한다.
struct PreviewSearchCoordinatorBuildable: SearchCoordinatorBuildable {
    func makeSearchCoordinator(
        navigationController: UINavigationController,
        onRouteSelected: @escaping (LastRoute) -> Void
    ) -> any Coordinator {
        PreviewSearchCoordinator(onRouteSelected: onRouteSelected)
    }
}

final class PreviewSearchCoordinator: Coordinator {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?

    private let onRouteSelected: (LastRoute) -> Void

    init(onRouteSelected: @escaping (LastRoute) -> Void) {
        self.onRouteSelected = onRouteSelected
    }

    func start() {
        onRouteSelected(Self.makeCannedRoute())
        finish()
    }

    private static func makeCannedRoute() -> LastRoute {
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
