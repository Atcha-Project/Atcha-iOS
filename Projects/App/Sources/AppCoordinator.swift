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
                // 앱 시작 동기화 + 포그라운드 관찰 시작 — 세션이 준비된 뒤에만.
                self.container.alarmSyncService.activate()
            } catch {
                guard !Task.isCancelled else { return }
                // 원인별 문구 분기(Phase 16) — 오프라인만 구분, 그 외는 일시 장애 안내.
                self.splashViewController?.showRetry(
                    message: BootstrapFailureMessage.text(for: error)
                )
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

    /// 노티 탭 랜딩(Phase 15) — presented를 접고 내비게이션을 홈 루트로 되돌린다.
    /// 이 앱의 노티는 폴백 노티뿐이고 목적지는 항상 홈(배너·카드가 최신 상태를 말한다).
    /// 스플래시 단계의 탭이면 popToRoot가 스플래시에 머무를 뿐 — 부트스트랩 후 홈 자연 랜딩.
    func returnToHome() {
        navigationController.presentedViewController?.dismiss(animated: false)
        // 프로그램적 pop도 SearchCoordinator의 didShow 정리 경로를 탄다(Phase 17) —
        // 백 버튼·스와이프 백과 같은 단일 지점에서 자식 코디네이터가 finish된다.
        navigationController.popToRootViewController(animated: false)
    }

    func coordinatorDidFinish(_ coordinator: any Coordinator) {
        removeChild(coordinator)
    }
}
