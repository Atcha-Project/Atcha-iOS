import CoreCoordinator
import UIKit

final class AppCoordinator: Coordinator, CoordinatorFinishDelegate {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?

    // Window root — the app coordinator owns its navigation controller.
    private let navigationController: UINavigationController
    private let container: AppDIContainer

    private weak var splashViewController: SplashViewController?

    init(navigationController: UINavigationController, container: AppDIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    func start() {
        let splash = SplashViewController()
        splash.onRetryTapped = { [weak self] in self?.bootstrap() }
        splashViewController = splash
        navigationController.setViewControllers([splash], animated: false)
        bootstrap()
    }

    private func bootstrap() {
        splashViewController?.showLoading()
        // 세션 판정은 동기(키체인 존재 여부) — 토큰 유효성은 첫 인증 요청이 증명한다.
        switch container.authSessionManager.bootstrapState() {
        case .active:
            startHome()
            // 앱 시작 동기화 + 포그라운드 관찰 시작 — 세션이 준비된 뒤에만.
            container.alarmSyncService.activate()
        case .loginRequired:
            // 임시(커밋 1): AuthFeature 통합 커밋에서 로그인 시트 present로 교체.
            splashViewController?.showRetry(message: "로그인이 필요해요")
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
