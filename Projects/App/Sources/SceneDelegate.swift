import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene,
              // 조합 루트는 AppDelegate 소유 — 푸시 경로(scene 없음)와 공유한다.
              let container = (UIApplication.shared.delegate as? AppDelegate)?.container
        else { return }
        let navigationController = UINavigationController()
        let coordinator = AppCoordinator(
            navigationController: navigationController,
            container: container
        )

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        appCoordinator = coordinator
        coordinator.start()

        #if DEV
        installDevChangeButton(in: window, container: container)
        #endif
    }

    #if DEV
    // MARK: - Phase 11 변경 시뮬레이터 (DEV 한정 플로팅 버튼)

    /// 실서버가 변경을 내려줄 수 없는 동안 "막차 변경 → 알람 재스케줄 → LA/배너 표출"을
    /// 사람이 검수할 진입점. 주입 설정 후 3초 지연 뒤 사일런트 푸시 도착을 시뮬레이션한다 —
    /// 3초는 홈 버튼으로 백그라운드 전환할 시간(잠금화면 LA alert 경로 검수용).
    private func installDevChangeButton(in window: UIWindow, container: AppDIContainer) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "변경"
        configuration.baseBackgroundColor = UIColor.systemIndigo.withAlphaComponent(0.75)
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 8, leading: 12, bottom: 8, trailing: 12
        )
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(
            UIAction { [weak self, weak button] _ in
                self?.presentDevChangeMenu(container: container, sourceView: button)
            },
            for: .touchUpInside
        )
        // rootViewController 위 window 직속 — 네비게이션 푸시와 무관하게 항상 떠 있는다.
        window.addSubview(button)
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(
                equalTo: window.safeAreaLayoutGuide.trailingAnchor, constant: -16
            ),
            button.bottomAnchor.constraint(
                equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -96
            ),
        ])
    }

    private func presentDevChangeMenu(container: AppDIContainer, sourceView: UIView?) {
        guard let window, var top = window.rootViewController else { return }
        while let presented = top.presentedViewController { top = presented }

        let sheet = UIAlertController(
            title: "변경 시뮬레이터 (DEV)",
            message: "선택 후 3초 안에 백그라운드로 전환하면 잠금화면 LA alert 경로, "
                + "그대로 두면 인앱(배너 강조+토스트) 경로를 검수합니다.",
            preferredStyle: .actionSheet
        )
        func add(
            _ title: String,
            injection: DevChangeSimulator.Injection?,
            delay: TimeInterval,
            style: UIAlertAction.Style = .default
        ) {
            sheet.addAction(UIAlertAction(title: title, style: style) { _ in
                Self.simulateChange(injection, after: delay, container: container)
            })
        }
        add("5분 앞당김 (3초 후)", injection: .advance(5 * 60), delay: 3)
        add("15분 앞당김 (3초 후)", injection: .advance(15 * 60), delay: 3)
        add("10분 늦춤 (3초 후)", injection: .delay(10 * 60), delay: 3)
        add("운행 종료 (3초 후)", injection: .end, delay: 3, style: .destructive)
        add("즉시 refresh", injection: nil, delay: 0)
        sheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = sourceView ?? window
            popover.sourceRect = sourceView?.bounds
                ?? CGRect(origin: window.center, size: .zero)
        }
        top.present(sheet, animated: true)
    }

    /// 주입 설정 → 지연 → 사일런트 푸시 수신과 동일 경로(syncFromPush) 호출.
    /// injection이 nil이면 주입 없이 즉시 refresh만 한다(unchanged 경로·실서버 검수).
    private static func simulateChange(
        _ injection: DevChangeSimulator.Injection?,
        after delay: TimeInterval,
        container: AppDIContainer
    ) {
        Task { @MainActor in
            if let injection {
                DevChangeSimulator.shared.inject(injection)
            }
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            _ = await container.alarmSyncService.syncFromPush()
        }
    }
    #endif
}
