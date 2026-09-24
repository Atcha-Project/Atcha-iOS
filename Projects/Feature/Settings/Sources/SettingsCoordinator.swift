import CoreCoordinator
import SafariServices
import UIKit

// NSObject 상속은 UINavigationControllerDelegate(NSObjectProtocol) 요구 — 이탈 경로
// (백 버튼·스와이프 백·popToRoot·세션 만료의 setViewControllers)를 didShow 한 지점에서
// 정리한다(SearchCoordinator와 같은 규약).
final class SettingsCoordinator: NSObject, Coordinator {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?

    // The App (window root) owns the navigation controller.
    private weak var navigationController: UINavigationController?
    private let container: SettingsDIContainer
    private weak var rootViewController: UIViewController?
    // 주소 저장 후 복귀 시 토스트·재조회를 알리기 위한 참조 — VC가 소유한다.
    private weak var settingsViewModel: SettingsViewModel?
    private weak var previousNavigationDelegate: (any UINavigationControllerDelegate)?
    private var isFinished = false

    init(navigationController: UINavigationController, container: SettingsDIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        guard let navigationController else { return }
        let (viewController, viewModel) = container.makeSettingsScreen()
        viewModel.onRoute = { [weak self] route in self?.handle(route) }
        rootViewController = viewController
        settingsViewModel = viewModel
        previousNavigationDelegate = navigationController.delegate
        navigationController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func handle(_ route: SettingsViewModel.Route) {
        guard let navigationController else { return }
        switch route {
        case .homeAddress:
            let viewController = container.makeHomeAddressViewController { [weak self] in
                guard let self, let root = self.rootViewController else { return }
                self.navigationController?.popToViewController(root, animated: true)
                self.settingsViewModel?.homeAddressDidChange()
            }
            navigationController.pushViewController(viewController, animated: true)
        case .withdraw:
            navigationController.pushViewController(container.makeWithdrawViewController(), animated: true)
        case let .externalLink(url):
            if url.scheme?.hasPrefix("http") == true {
                navigationController.present(SFSafariViewController(url: url), animated: true)
            } else {
                UIApplication.shared.open(url)
            }
        }
    }
}

extension SettingsCoordinator: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        guard !isFinished else { return }
        // 설정 루트가 스택에 남아 있으면(하위 화면 push·pop 포함) 플로우 진행 중이다.
        if let rootViewController,
           navigationController.viewControllers.contains(rootViewController) {
            return
        }
        isFinished = true
        navigationController.delegate = previousNavigationDelegate
        finish()
    }
}
