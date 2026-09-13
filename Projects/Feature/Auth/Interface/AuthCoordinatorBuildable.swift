import CoreCoordinator
import UIKit

/// Entry point other modules use to start the login flow.
/// The concrete builder is the feature's DIContainer; wiring happens at the
/// App composition root.
@MainActor
public protocol AuthCoordinatorBuildable {
    /// 강제 로그인 플로우 — 성공(세션 채택 완료) 시에만 onAuthenticated가 불린다.
    /// 취소 경로는 없다(시트 dismiss 제스처 미제공).
    func makeLoginCoordinator(
        navigationController: UINavigationController,
        onAuthenticated: @escaping () -> Void
    ) -> any Coordinator
}
