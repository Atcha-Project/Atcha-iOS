import CoreCoordinator
import Domain
import HomeFeatureInterface
import UIKit

/// Assembles the Home feature's screens. Coordinators own flow only;
/// screen/ViewModel assembly stays here so adding screens never bloats
/// coordinator initializers.
public final class HomeDIContainer: HomeCoordinatorBuildable {
    private let fetchHomeUseCase: any FetchHomeUseCase

    public init(fetchHomeUseCase: any FetchHomeUseCase) {
        self.fetchHomeUseCase = fetchHomeUseCase
    }

    public func makeHomeCoordinator(navigationController: UINavigationController) -> any Coordinator {
        HomeCoordinator(navigationController: navigationController, container: self)
    }

    func makeHomeViewController() -> UIViewController {
        HomeViewController(viewModel: HomeViewModel(fetchHomeUseCase: fetchHomeUseCase))
    }
}
