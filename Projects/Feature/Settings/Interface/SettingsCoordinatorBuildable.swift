import CoreCoordinator
import UIKit

/// Entry point other modules use to start the Settings flow.
/// 로그아웃·탈퇴 후의 로그인 복귀는 앱의 세션 만료 관찰이 맡는다 — 여기엔 완료 콜백이 없다.
@MainActor
public protocol SettingsCoordinatorBuildable {
    func makeSettingsCoordinator(navigationController: UINavigationController) -> any Coordinator
}
