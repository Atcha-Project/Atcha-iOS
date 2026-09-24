import CoreCoordinator
import UIKit

final class AppCoordinator: Coordinator, CoordinatorFinishDelegate {
    var childCoordinators: [any Coordinator] = []
    weak var finishDelegate: (any CoordinatorFinishDelegate)?

    // Window root — the app coordinator owns its navigation controller.
    private let navigationController: UINavigationController
    private let container: AppDIContainer

    private weak var splashViewController: SplashViewController?
    private var sessionExpiryTask: Task<Void, Never>?
    /// 로그인 플로우 표시 중 가드 — 만료 스트림의 중복 yield에 로그인을 겹치지 않는다.
    private var isShowingLogin = false
    /// 세션 만료 경유 재로그인이면 성공 직후 수동 동기화 1회 — activate()의 시작
    /// 동기화는 최초 1회 가드라 재로그인 경로에선 돌지 않기 때문.
    private var needsSyncAfterLogin = false

    init(navigationController: UINavigationController, container: AppDIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    deinit {
        sessionExpiryTask?.cancel()
    }

    func start() {
        let splash = SplashViewController()
        splash.onRetryTapped = { [weak self] in self?.bootstrap() }
        splashViewController = splash
        navigationController.setViewControllers([splash], animated: false)
        observeSessionExpiry()
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
            showLogin()
        }
    }

    /// 강제 로그인 — 스플래시를 root로 유지한 채 로그인 시트를 present한다
    /// (스플래시 배경 위 바텀시트 = 레거시와 같은 시각 결과).
    private func showLogin() {
        guard !isShowingLogin else { return }
        isShowingLogin = true
        let loginCoordinator = container.makeAuthDIContainer().makeLoginCoordinator(
            navigationController: navigationController,
            onAuthenticated: { [weak self] in
                guard let self else { return }
                self.isShowingLogin = false
                self.startHome()
                self.container.alarmSyncService.activate()
                if self.needsSyncAfterLogin {
                    self.needsSyncAfterLogin = false
                    let syncService = self.container.alarmSyncService
                    Task { await syncService.syncNow() }
                }
            }
        )
        loginCoordinator.finishDelegate = self
        addChild(loginCoordinator)
        loginCoordinator.start()
    }

    /// refresh 확정 사망(AuthSessionManager.sessionExpired) 관찰 — 홈을 접고 스플래시
    /// 위 로그인으로 되돌린다. 스트림은 단일 소비자(이 코디네이터) 전제.
    private func observeSessionExpiry() {
        sessionExpiryTask = Task { [weak self] in
            guard let stream = self?.container.authSessionManager.sessionExpired else { return }
            for await _ in stream {
                guard let self, !Task.isCancelled else { return }
                self.handleSessionExpiry()
            }
        }
    }

    private func handleSessionExpiry() {
        guard !isShowingLogin else { return }
        needsSyncAfterLogin = true
        navigationController.presentedViewController?.dismiss(animated: false)
        // setViewControllers가 didShow를 태워 SearchCoordinator류의 정리 경로도 돈다.
        let splash = SplashViewController()
        splash.onRetryTapped = { [weak self] in self?.bootstrap() }
        splashViewController = splash
        navigationController.setViewControllers([splash], animated: false)
        childCoordinators.removeAll()
        showLogin()
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
