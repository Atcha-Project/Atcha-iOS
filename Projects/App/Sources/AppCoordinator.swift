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
    /// 게스트 부트스트랩 in-flight — 만료 스트림의 중복 yield나 재시도 연타에
    /// /auth/guest를 겹쳐 쏘지 않는다.
    private var bootstrapTask: Task<Void, Never>?
    /// 로그인 플로우 표시 중 가드 — 만료 스트림의 중복 yield에 로그인을 겹치지 않는다.
    private var isShowingLogin = false
    /// 세션 만료 경유 재인증이면 성공 직후 수동 동기화 1회 — activate()의 시작
    /// 동기화는 최초 1회 가드라 재인증 경로에선 돌지 않기 때문.
    private var needsSyncAfterLogin = false

    init(navigationController: UINavigationController, container: AppDIContainer) {
        self.navigationController = navigationController
        self.container = container
    }

    deinit {
        sessionExpiryTask?.cancel()
        bootstrapTask?.cancel()
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
            enterHome()
        case .loginRequired:
            signInAsGuest()
        }
    }

    private func enterHome() {
        startHome()
        // 앱 시작 동기화 + 포그라운드 관찰 시작 — 세션이 준비된 뒤에만.
        container.alarmSyncService.activate()
    }

    /// 게스트 부트스트랩(POST /auth/guest) — 토큰이 없으면 deviceId로 계정을 만들거나
    /// 되찾는다. 서버 호출이라 여기서 부트스트랩이 비동기가 되고, 그래서 비로소
    /// 스플래시의 실패 표면화(showRetry)가 실제로 쓰인다.
    private func signInAsGuest() {
        // in-flight면 재시도 연타·만료 중복 yield에도 /auth/guest를 겹쳐 쏘지 않는다.
        guard bootstrapTask == nil else { return }
        let useCase = container.makeSignInAsGuestUseCase()
        bootstrapTask = Task { [weak self] in
            defer { self?.bootstrapTask = nil }
            do {
                try await useCase.execute()
                guard let self, !Task.isCancelled else { return }
                self.enterHome()
                // 게스트 가입 시 FCM 토큰이 아직 없었을 수 있다 — 세션이 생긴 직후 한 번 맞춘다.
                self.syncPushTokenAfterLogin()
                if self.needsSyncAfterLogin {
                    self.needsSyncAfterLogin = false
                    let syncService = self.container.alarmSyncService
                    Task { await syncService.syncNow() }
                }
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.splashViewController?.showRetry(
                    message: BootstrapFailureMessage.text(for: error)
                )
            }
        }
    }

    /// 소셜 로그인 시트 — 스플래시를 root로 유지한 채 present한다
    /// (스플래시 배경 위 바텀시트 = 레거시와 같은 시각 결과).
    ///
    /// 게스트 인증 전환(2026-09-24) 이후 **호출처가 없다.** 서버가 게스트 계정으로
    /// 부트스트랩을 처리하므로 강제 로그인 단계 자체가 사라졌다. 소셜 계정 승격이
    /// 도입되면 이 경로가 그대로 진입점이 되므로 AuthFeature와 함께 남겨둔다.
    @available(*, deprecated, message: "게스트 부트스트랩으로 대체됨. 소셜 계정 승격 도입 시 재사용.")
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
        guard bootstrapTask == nil, !isShowingLogin else { return }
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
        splash.showLoading()
        // 서버 계약: reissue가 죽어도 같은 deviceId로 /auth/guest를 부르면 같은 계정이
        // 돌아온다 — 만료가 로그인 화면이 아니라 조용한 재인증으로 끝나는 근거다.
        signInAsGuest()
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
