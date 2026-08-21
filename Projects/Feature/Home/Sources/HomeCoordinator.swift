import CoreCoordinator
import UIKit

final class HomeCoordinator: Coordinator {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?

    // The App (window root) owns the navigation controller.
    private weak var navigationController: UINavigationController?
    private let container: HomeDIContainer

    init(navigationController: UINavigationController, container: HomeDIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let viewController = container.makeHomeViewController()
        navigationController?.pushViewController(viewController, animated: false)
    }
}
