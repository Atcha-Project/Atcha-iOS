import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene,
              // 조합 루트는 AppDelegate 소유 — 푸시 경로(scene 없음)와 공유한다.
              let container = (UIApplication.shared.delegate as? AppDelegate)?.container
        else { return }
        let navigationController = UINavigationController()
        let coordinator = AppCoordinator(
            navigationController: navigationController,
            container: container
        )

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        appCoordinator = coordinator
        coordinator.start()
    }
}
