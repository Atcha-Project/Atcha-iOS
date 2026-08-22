import CoreCoordinator
import Domain
import UIKit

/// Entry point other modules use to start the Search flow.
/// The concrete builder is the feature's DIContainer; wiring happens at the
/// App composition root.
@MainActor
public protocol SearchCoordinatorBuildable {
    func makeSearchCoordinator(
        navigationController: UINavigationController,
        onRouteSelected: @escaping (LastRoute) -> Void
    ) -> any Coordinator
}
