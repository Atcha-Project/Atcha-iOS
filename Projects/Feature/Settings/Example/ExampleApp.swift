import CoreCoordinator
import Domain
import SettingsFeature
import SettingsFeatureInterface
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
    private var settingsCoordinator: (any Coordinator)?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let launcher = LauncherViewController()
        launcher.onStart = { [weak self] in self?.startSettingsFlow() }
        navigationController.viewControllers = [launcher]

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }

    private func startSettingsFlow() {
        let container = SettingsDIContainer(
            getUserProfileUseCase: PreviewGetUserProfileUseCase(),
            logoutUseCase: PreviewLogoutUseCase(),
            withdrawUseCase: PreviewWithdrawUseCase(),
            updateHomeAddressUseCase: PreviewUpdateHomeAddressUseCase(),
            searchPlacesUseCase: PreviewSearchPlacesUseCase(),
            getCurrentLocationUseCase: PreviewGetCurrentLocationUseCase(),
            reverseGeocodeUseCase: PreviewReverseGeocodeUseCase(),
            checkAppUpdateUseCase: PreviewCheckAppUpdateUseCase(),
            currentVersion: "2.0.0",
            appStoreURL: URL(string: "https://apps.apple.com")
        )
        let coordinator = container.makeSettingsCoordinator(navigationController: navigationController)
        coordinator.finishDelegate = self
        settingsCoordinator = coordinator
        coordinator.start()
    }
}

extension SceneDelegate: CoordinatorFinishDelegate {
    func coordinatorDidFinish(_ coordinator: any Coordinator) {
        settingsCoordinator = nil
    }
}

private final class LauncherViewController: UIViewController {
    var onStart: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "SettingsFeature Example"

        let startButton = UIButton(type: .system)
        startButton.setTitle("설정 열기", for: .normal)
        startButton.addAction(UIAction { [weak self] _ in self?.onStart?() }, for: .touchUpInside)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

// Example 스텁 — Data 무의존으로 피처 단독 실행(Tests 스텁과의 중복은 의도된 트레이드오프).
// "부산" 검색 결과를 고르면 서비스 지역 밖 토스트, 그 외는 저장 성공 경로를 시연한다.

private struct PreviewError: Error {}

private struct PreviewGetUserProfileUseCase: GetUserProfileUseCase {
    func execute() async throws -> UserProfile {
        try? await Task.sleep(for: .milliseconds(500))
        return UserProfile(userID: 1, providerID: nil, nickname: nil, address: "서울 중구 세종대로 110", coordinate: nil, appVersion: nil)
    }
}

private struct PreviewLogoutUseCase: LogoutUseCase {
    func execute() async {}
}

private struct PreviewWithdrawUseCase: WithdrawUseCase {
    func execute(reason: String?) async throws {
        try? await Task.sleep(for: .seconds(1))
        throw PreviewError()
    }
}

private struct PreviewUpdateHomeAddressUseCase: UpdateHomeAddressUseCase {
    func execute(address: String?, coordinate: Coordinate) async throws {
        try? await Task.sleep(for: .milliseconds(500))
        if address?.contains("부산") == true { throw UpdateHomeAddressError.outOfServiceRegion }
    }
}

private struct PreviewSearchPlacesUseCase: SearchPlacesUseCase {
    func execute(keyword: String, near coordinate: Coordinate?) async throws -> [Place] {
        [
            Place(name: "\(keyword) 서울점", address: "서울 중구 세종대로 110", coordinate: Coordinate(latitude: 37.5665, longitude: 126.9780)),
            Place(name: "\(keyword) 부산점", address: "부산 해운대구 해운대해변로 264", coordinate: Coordinate(latitude: 35.1587, longitude: 129.1604)),
        ]
    }
}

private struct PreviewGetCurrentLocationUseCase: GetCurrentLocationUseCase {
    func execute() async throws -> Coordinate {
        Coordinate(latitude: 37.5665, longitude: 126.9780)
    }
}

private struct PreviewReverseGeocodeUseCase: ReverseGeocodeUseCase {
    func execute(coordinate: Coordinate) async throws -> Place {
        Place(name: "서울시청", address: "서울 중구 세종대로 110", coordinate: coordinate)
    }
}

private struct PreviewCheckAppUpdateUseCase: CheckAppUpdateUseCase {
    func execute(currentVersion: String) async throws -> AppUpdateStatus {
        .recommended(latest: "2.1.0")
    }
}
