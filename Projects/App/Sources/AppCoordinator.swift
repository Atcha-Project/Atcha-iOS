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
    /// 만료 스트림의 중복 yield(동시 401 등)에 게스트 재발급을 겹치지 않는다.
    private var isReissuingSession = false

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
        // 다른 화면이 present돼 있으면 그 위에 — 가장 위의 presented에 얹는다.
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
        case .noSession:
            // 게스트 전용 — 로그인 화면 없이 기기 ID로 게스트 세션을 발급받는다.
            let issueGuestSession = container.issueGuestSessionUseCase
            Task { [weak self] in
                do {
                    try await issueGuestSession.execute()
                    self?.enterHome()
                } catch {
                    self?.splashViewController?.showRetry(message: BootstrapFailureMessage.text(for: error))
                }
            }
        }
    }

    private func enterHome() {
        startHome()
        // 앱 시작 동기화 + 포그라운드 관찰 시작 — 세션이 준비된 뒤에만.
        container.alarmSyncService.activate()
        syncPushToken()
    }

    /// refresh 확정 사망(AuthSessionManager.sessionExpired) 관찰. 스트림은 단일 소비자(이 코디네이터) 전제.
    private func observeSessionExpiry() {
        sessionExpiryTask = Task { [weak self] in
            guard let stream = self?.container.authSessionManager.sessionExpired else { return }
            for await _ in stream {
                guard let self, !Task.isCancelled else { return }
                self.handleSessionExpiry()
            }
        }
    }

    /// 게스트는 돌아갈 로그인 화면이 없다 — 화면은 그대로 두고 같은 기기 ID로 조용히 재발급한다.
    /// 서버가 같은 게스트 회원을 돌려주는 계약이라 알람·집 주소는 정리하지 않는다.
    /// 재발급이 실패하면 다음 401이 다시 만료를 yield해 자연 재시도가 된다.
    private func handleSessionExpiry() {
        guard !isReissuingSession else { return }
        isReissuingSession = true
        let issueGuestSession = container.issueGuestSessionUseCase
        let syncService = container.alarmSyncService
        Task { [weak self] in
            let succeeded = (try? await issueGuestSession.execute()) != nil
            self?.isReissuingSession = false
            // 만료 사이에 실패한 동기화를 메운다(activate의 시작 동기화는 최초 1회 가드).
            if succeeded { await syncService.syncNow() }
        }
    }

    /// 발급 요청 이후 토큰이 갱신됐을 수 있다 — 세션이 생긴 직후 현재 토큰을 한 번 맞춘다.
    private func syncPushToken() {
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
