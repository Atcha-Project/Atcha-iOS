import CoreCoordinator
import UIKit

/// Entry point other modules use to start the Home flow.
/// The concrete builder is the feature's DIContainer; wiring happens at the
/// App composition root.
@MainActor
public protocol HomeCoordinatorBuildable {
    func makeHomeCoordinator(navigationController: UINavigationController) -> any Coordinator
}
