import CoreCoordinator
import UIKit

final class LoginCoordinator: Coordinator {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?

    // The App (window root) owns the navigation controller.
    private weak var navigationController: UINavigationController?
    private let container: AuthDIContainer
    private let onAuthenticated: () -> Void
    private weak var loginViewController: LoginViewController?

    init(
        navigationController: UINavigationController,
        container: AuthDIContainer,
        onAuthenticated: @escaping () -> Void
    ) {
        self.navigationController = navigationController
        self.container = container
        self.onAuthenticated = onAuthenticated
    }

    func start() {
        guard let navigationController else { return }
        let viewController = container.makeLoginViewController(onAuthenticated: { [weak self] in
            self?.completeFlow()
        })
        loginViewController = viewController
        navigationController.present(viewController, animated: false)
    }

    /// 성공 유일 종료 경로 — 시트 하강 연출 후 onAuthenticated → finish.
    private func completeFlow() {
        guard let loginViewController else {
            onAuthenticated()
            finish()
            return
        }
        loginViewController.animateDismiss { [weak self] in
            guard let self else { return }
            self.onAuthenticated()
            self.finish()
        }
    }
}
