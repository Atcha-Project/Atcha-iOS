import AuthFeature
import AuthFeatureInterface
import CoreCoordinator
import Domain
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let navigationController = UINavigationController()
    private var loginCoordinator: (any Coordinator)?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let launcher = LauncherViewController()
        launcher.onStart = { [weak self] in self?.startLoginFlow() }
        navigationController.viewControllers = [launcher]

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }

    private func startLoginFlow() {
        let container = AuthDIContainer(signInUseCase: PreviewSignInUseCase())
        let coordinator = container.makeLoginCoordinator(
            navigationController: navigationController,
            onAuthenticated: { [weak self] in self?.showAuthenticated() }
        )
        coordinator.finishDelegate = self
        loginCoordinator = coordinator
        coordinator.start()
    }

    private func showAuthenticated() {
        let alert = UIAlertController(title: "로그인 완료", message: "세션 채택 성공 경로", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        navigationController.present(alert, animated: true)
    }
}

extension SceneDelegate: CoordinatorFinishDelegate {
    // finish 후 런처로 복귀 — 플로우를 반복 시연할 수 있다.
    func coordinatorDidFinish(_ coordinator: any Coordinator) {
        loginCoordinator = nil
    }
}

private final class LauncherViewController: UIViewController {
    var onStart: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "AuthFeature Example"

        let startButton = UIButton(type: .system)
        startButton.setTitle("로그인 시트 열기 (미가입→실패→성공 순환)", for: .normal)
        startButton.addAction(UIAction { [weak self] _ in self?.onStart?() }, for: .touchUpInside)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(startButton)
        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}

/// 탭할 때마다 미가입 안내 → 실패 토스트 → 성공을 순환 — 세 UX를 모두 시연한다.
/// (스텁이 Tests와 중복되는 것은 의도된 트레이드오프 — 규약 참고.)
@MainActor
private final class PreviewSignInUseCase: SignInUseCase {
    private var attempt = 0

    private struct PreviewError: Error {}

    func execute(provider: SocialLoginProvider) async throws -> SignInOutcome {
        try? await Task.sleep(for: .seconds(1))
        defer { attempt += 1 }
        switch attempt % 3 {
        case 0: return .needsSignUp
        case 1: throw PreviewError()
        default: return .success
        }
    }
}
