import CoreCoordinator
import Domain
import SearchFeature
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
    private let navigationController = UINavigationController()
    private var searchCoordinator: (any Coordinator)?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let launcher = LauncherViewController()
        launcher.onStart = { [weak self] in self?.startSearchFlow() }
        navigationController.viewControllers = [launcher]

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }

    private func startSearchFlow() {
        let container = SearchDIContainer(
            searchPlacesUseCase: PreviewSearchPlacesUseCase(),
            searchLastRoutesUseCase: PreviewSearchLastRoutesUseCase(),
            recentSearchesUseCase: PreviewRecentSearchesUseCase()
        )
        let coordinator = container.makeSearchCoordinator(
            navigationController: navigationController,
            initialField: .departure,
            onRouteSelected: { [weak self] route, arrival in
                self?.showSelectedRoute(route, arrival: arrival)
            }
        )
        coordinator.finishDelegate = self
        searchCoordinator = coordinator
        coordinator.start()
    }

    private func showSelectedRoute(_ route: LastRoute, arrival: Place) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let alert = UIAlertController(
            title: "경로 선택됨",
            message: "\(formatter.string(from: route.departureTime)) 출발 → \(arrival.name) · 환승 \(route.transferCount)회 (id: \(route.id))",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        navigationController.present(alert, animated: true)
    }
}

extension SceneDelegate: CoordinatorFinishDelegate {
    // finish 후 런처로 복귀 — 플로우를 반복 시연할 수 있다.
    func coordinatorDidFinish(_ coordinator: any Coordinator) {
        searchCoordinator = nil
    }
}

final class LauncherViewController: UIViewController {
    var onStart: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "SearchFeature Example"

        var configuration = UIButton.Configuration.filled()
        configuration.title = "검색 플로우 시작"
        let button = UIButton(
            configuration: configuration,
            primaryAction: UIAction { [weak self] _ in self?.onStart?() }
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

// MARK: - 스텁 (Example apps wire stub use cases — no Data/network dependency.)

nonisolated enum PreviewScenario {
    // 이 좌표의 장소를 도착지로 고르면 각각의 빈 상태를 시연한다.
    static let serviceEndedCoordinate = Coordinate(latitude: 1, longitude: 1)
    static let noRouteCoordinate = Coordinate(latitude: 2, longitude: 2)

    static let catalog: [Place] = [
        Place(name: "강남역", address: "서울 강남구 강남대로 396", coordinate: Coordinate(latitude: 37.4980, longitude: 127.0276)),
        Place(name: "홍대입구역", address: "서울 마포구 양화로 지하 160", coordinate: Coordinate(latitude: 37.5568, longitude: 126.9237)),
        Place(name: "당산역", address: "서울 영등포구 당산로 229", coordinate: Coordinate(latitude: 37.5343, longitude: 126.9026)),
        Place(name: "판교역", address: "경기 성남시 분당구 판교역로 160", coordinate: Coordinate(latitude: 37.3948, longitude: 127.1112)),
        Place(name: "막차 종료 데모 장소", address: "도착지로 선택하면 '오늘 막차 종료'를 보여줘요", coordinate: serviceEndedCoordinate),
        Place(name: "경로 없음 데모 장소", address: "도착지로 선택하면 '경로 없음'을 보여줘요", coordinate: noRouteCoordinate),
    ]
}

struct PreviewSearchPlacesUseCase: SearchPlacesUseCase {
    func execute(keyword: String, near coordinate: Coordinate?) async throws -> [Place] {
        // 디바운스가 체감되도록 실서버 지연을 흉내낸다.
        try? await Task.sleep(for: .milliseconds(300))
        let matches = PreviewScenario.catalog.filter { $0.name.localizedStandardContains(keyword) }
        return matches.isEmpty ? PreviewScenario.catalog : matches
    }
}

struct PreviewSearchLastRoutesUseCase: SearchLastRoutesUseCase {
    func execute(start: Coordinate, end: Coordinate) async throws -> LastRouteSearchResult {
        try? await Task.sleep(for: .milliseconds(500))
        if end == PreviewScenario.serviceEndedCoordinate { return .serviceEnded }
        if end == PreviewScenario.noRouteCoordinate { return .noRoute }
        return .available([
            makeRoute(id: "preview-1", hour: 23, minute: 31, transferCount: 2),
            makeRoute(id: "preview-2", hour: 23, minute: 18, transferCount: 1),
            makeRoute(id: "preview-3", hour: 23, minute: 5, transferCount: 3),
        ])
    }

    private func makeRoute(id: String, hour: Int, minute: Int, transferCount: Int) -> LastRoute {
        let departure = Calendar.current.date(
            bySettingHour: hour, minute: minute, second: 0, of: Date()
        ) ?? Date()
        let gangnam = RoutePoint(name: "강남역", coordinate: Coordinate(latitude: 37.4980, longitude: 127.0276))
        let dangsan = RoutePoint(name: "당산역", coordinate: Coordinate(latitude: 37.5343, longitude: 126.9026))
        let guro = RoutePoint(name: "구로디지털단지", coordinate: Coordinate(latitude: 37.4852, longitude: 126.9015))
        return LastRoute(
            id: id,
            departureTime: departure,
            totalTime: 2940,
            totalWalkTime: 660,
            transferCount: transferCount,
            totalDistance: 14200,
            totalWalkDistance: 900,
            legs: [
                TransportLeg(
                    mode: .walk, sectionTime: 300, distance: 400,
                    departureTime: nil, routeName: nil, lineType: nil,
                    start: nil, end: nil,
                    subwayFinalStation: nil, subwayDirection: nil,
                    isExpressSubway: false, isLastSubway: false
                ),
                TransportLeg(
                    mode: .subway, sectionTime: 1200, distance: 9000,
                    departureTime: departure, routeName: "2호선", lineType: "2",
                    start: gangnam, end: dangsan,
                    subwayFinalStation: "성수", subwayDirection: "외선",
                    isExpressSubway: false, isLastSubway: true
                ),
                TransportLeg(
                    mode: .bus, sectionTime: 1080, distance: 4400,
                    departureTime: nil, routeName: "간선:472", lineType: "11",
                    start: dangsan, end: guro,
                    subwayFinalStation: nil, subwayDirection: nil,
                    isExpressSubway: false, isLastSubway: false
                ),
                TransportLeg(
                    mode: .walk, sectionTime: 360, distance: 400,
                    departureTime: nil, routeName: nil, lineType: nil,
                    start: nil, end: nil,
                    subwayFinalStation: nil, subwayDirection: nil,
                    isExpressSubway: false, isLastSubway: false
                ),
            ]
        )
    }
}

actor PreviewRecentSearchesStore {
    private var places: [Place]

    init(seed: [Place]) {
        places = seed
    }

    func fetch() -> [Place] { places }

    func save(_ place: Place) {
        places.removeAll { $0 == place }
        places.insert(place, at: 0)
        places = Array(places.prefix(10))
    }

    func remove(_ place: Place) {
        places.removeAll { $0 == place }
    }
}

struct PreviewRecentSearchesUseCase: RecentSearchesUseCase {
    // 데모 장소를 최근 검색에 심어 3가지 상태를 바로 시연할 수 있게 한다.
    private let store = PreviewRecentSearchesStore(seed: [
        PreviewScenario.catalog[0],
        PreviewScenario.catalog[4],
        PreviewScenario.catalog[5],
    ])

    func fetch() async throws -> [Place] { await store.fetch() }
    func save(_ place: Place) async throws { await store.save(place) }
    func remove(_ place: Place) async throws { await store.remove(place) }
}
