import CoreCoordinator
import UIKit

final class AppCoordinator: Coordinator, CoordinatorFinishDelegate {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?

    // Window root — the app coordinator owns its navigation controller.
    private let navigationController: UINavigationController
    private let container: AppDIContainer

    init(navigationController: UINavigationController, container: AppDIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let homeCoordinator = container.makeHomeDIContainer()
            .makeHomeCoordinator(navigationController: navigationController)
        homeCoordinator.finishDelegate = self
        addChild(homeCoordinator)
        homeCoordinator.start()
    }

    func coordinatorDidFinish(_ coordinator: any Coordinator) {
        removeChild(coordinator)
    }
}
