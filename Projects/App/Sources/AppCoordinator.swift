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
        checkForAppUpdate()
    }

    /// 부트스트랩과 병렬 — 결과가 늦거나 실패하면 아무 일도 없다(레거시 스플래시 정지 버그 방지).
    private func checkForAppUpdate() {
        let container = container
        Task { [weak self] in
            guard case .recommended = await container.checkForAppUpdate() else { return }
            self?.presentUpdateRecommendation()
        }
    }

    private func presentUpdateRecommendation() {
        let alert = UIAlertController(
            title: nil,
            message: "더 좋아진 앗차를 사용하기 위해\n업데이트를 권장해요",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "나중에", style: .cancel))
        alert.addAction(UIAlertAction(title: "업데이트", style: .default) { _ in
            UIApplication.shared.open(AppEnvironment.current.appStoreURL)
        })
        // 로그인 시트가 떠 있으면 그 위에 — 가장 위의 presented에 얹는다.
        var top: UIViewController = navigationController
        while let presented = top.presentedViewController { top = presented }
        top.present(alert, animated: true)
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
                self.syncPushTokenAfterLogin()
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
        // 로그아웃·탈퇴·강제 만료 공통 합류점 — 이전 계정의 알람이 로그인 화면에서 울리지 않게
        // 로컬 정리를 여기서 한 번 더 보장한다(로그아웃 경로의 선행 정리와 겹쳐도 멱등).
        let teardown = container.alarmSessionTeardown
        Task { await teardown.tearDown(cancelOnServer: false) }
        // 다음 계정에는 같은 FCM 토큰이라도 다시 전달해야 한다.
        container.syncPushTokenUseCase.reset()
        navigationController.presentedViewController?.dismiss(animated: false)
        // setViewControllers가 didShow를 태워 SearchCoordinator류의 정리 경로도 돈다.
        let splash = SplashViewController()
        splash.onRetryTapped = { [weak self] in self?.bootstrap() }
        splashViewController = splash
        navigationController.setViewControllers([splash], animated: false)
        childCoordinators.removeAll()
        showLogin()
    }

    /// 로그인 중에 토큰이 갱신됐을 수 있다 — 세션이 생긴 직후 현재 토큰을 한 번 맞춘다.
    private func syncPushTokenAfterLogin() {
        let syncPushToken = container.syncPushTokenUseCase
        Task {
            guard let token = await FCMPushTokenAdapter().currentPushToken() else { return }
            await syncPushToken.execute(token: token)
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
