import CoreCoordinator
import UIKit

final class AppCoordinator: Coordinator, CoordinatorFinishDelegate {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?

    // Window root — the app coordinator owns its navigation controller.
    private let navigationController: UINavigationController
    private let container: AppDIContainer

    private weak var splashViewController: SplashViewController?
    private var bootstrapTask: Task<Void, Never>?

    init(navigationController: UINavigationController, container: AppDIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    deinit {
        bootstrapTask?.cancel()
    }

    func start() {
        let splash = SplashViewController()
        splash.onRetryTapped = { [weak self] in self?.bootstrap() }
        splashViewController = splash
        navigationController.setViewControllers([splash], animated: false)
        bootstrap()
    }

    private func bootstrap() {
        bootstrapTask?.cancel()
        splashViewController?.showLoading()
        bootstrapTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.container.authSessionManager.bootstrap()
                guard !Task.isCancelled else { return }
                self.startHome()
            } catch {
                guard !Task.isCancelled else { return }
                self.splashViewController?.showRetry()
            }
        }
    }

    private func startHome() {
        let homeCoordinator = container.makeHomeDIContainer()
            .makeHomeCoordinator(navigationController: navigationController)
        homeCoordinator.finishDelegate = self
        addChild(homeCoordinator)
        homeCoordinator.start()
        // Home pushed its own root; drop the splash out from under it.
        if let splash = splashViewController {
            navigationController.viewControllers.removeAll { $0 === splash }
        }
    }

    func coordinatorDidFinish(_ coordinator: any Coordinator) {
        removeChild(coordinator)
    }
}
