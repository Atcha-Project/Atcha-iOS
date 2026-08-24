import CoreCoordinator
import Domain
import SearchFeatureInterface
import UIKit

final class HomeCoordinator: Coordinator, CoordinatorFinishDelegate {
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
        let viewController = container.makeHomeViewController(
            onSearchRequested: { [weak self] initialField, onRouteSelected in
                self?.startSearchFlow(initialField: initialField, onRouteSelected: onRouteSelected)
            }
        )
        navigationController?.pushViewController(viewController, animated: false)
    }

    // MARK: - 검색 플로우

    private func startSearchFlow(
        initialField: SearchEntryField,
        onRouteSelected: @escaping (LastRoute, Place) -> Void
    ) {
        guard let navigationController else { return }
        let child = container.makeSearchCoordinator(
            navigationController: navigationController,
            initialField: initialField,
            onRouteSelected: onRouteSelected
        )
        // start() 안에서 동기로 finish()될 수 있으므로(예: Example 스텁) 배선을 먼저 끝낸다.
        child.finishDelegate = self
        addChild(child)
        child.start()
    }

    // SearchCoordinator가 스스로 pop 후 finish()하므로 여기서는 제거만 한다.
    func coordinatorDidFinish(_ coordinator: any Coordinator) {
        removeChild(coordinator)
    }
}
