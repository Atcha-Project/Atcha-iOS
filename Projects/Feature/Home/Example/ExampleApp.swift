import CoreCoordinator
import Domain
import HomeFeature
import HomeFeatureInterface
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
        let container = HomeDIContainer(fetchHomeUseCase: PreviewFetchHomeUseCase())
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
struct PreviewFetchHomeUseCase: FetchHomeUseCase {
    func execute() async throws -> HomeSummary {
        try? await Task.sleep(for: .seconds(1))
        return HomeSummary(id: "preview", title: "막차까지 42분", subtitle: "Example 앱의 스텁 데이터입니다")
    }
}
