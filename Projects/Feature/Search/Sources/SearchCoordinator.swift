import CoreCoordinator
import Domain
import UIKit

final class SearchCoordinator: Coordinator {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?

    // The App (window root) owns the navigation controller.
    private weak var navigationController: UINavigationController?
    private let container: SearchDIContainer
    private let onRouteSelected: (LastRoute) -> Void

    init(
        navigationController: UINavigationController,
        container: SearchDIContainer,
        onRouteSelected: @escaping (LastRoute) -> Void
    ) {
        self.navigationController = navigationController
        self.container = container
        self.onRouteSelected = onRouteSelected
    }

    func start() {
        let viewController = container.makeSearchViewController(
            onRouteChosen: { [weak self] route in
                self?.onRouteSelected(route)
                self?.closeFlow()
            },
            onBack: { [weak self] in
                self?.closeFlow()
            }
        )
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func closeFlow() {
        navigationController?.popViewController(animated: true)
        finish()
    }
}
