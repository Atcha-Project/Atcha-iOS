import CoreCoordinator
import UIKit

/// Entry point other modules use to start the Settings flow.
@MainActor
public protocol SettingsCoordinatorBuildable {
    func makeSettingsCoordinator(navigationController: UINavigationController) -> any Coordinator
}
