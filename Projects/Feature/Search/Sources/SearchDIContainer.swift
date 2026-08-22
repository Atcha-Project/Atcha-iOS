import CoreCoordinator
import Domain
import SearchFeatureInterface
import UIKit

/// Assembles the Search feature's screens. Coordinators own flow only;
/// screen/ViewModel assembly stays here so adding screens never bloats
/// coordinator initializers.
public final class SearchDIContainer: SearchCoordinatorBuildable {
    private let searchPlacesUseCase: any SearchPlacesUseCase
    private let searchLastRoutesUseCase: any SearchLastRoutesUseCase
    private let recentSearchesUseCase: any RecentSearchesUseCase

    public init(
        searchPlacesUseCase: any SearchPlacesUseCase,
        searchLastRoutesUseCase: any SearchLastRoutesUseCase,
        recentSearchesUseCase: any RecentSearchesUseCase
    ) {
        self.searchPlacesUseCase = searchPlacesUseCase
        self.searchLastRoutesUseCase = searchLastRoutesUseCase
        self.recentSearchesUseCase = recentSearchesUseCase
    }

    public func makeSearchCoordinator(
        navigationController: UINavigationController,
        onRouteSelected: @escaping (LastRoute) -> Void
    ) -> any Coordinator {
        SearchCoordinator(
            navigationController: navigationController,
            container: self,
            onRouteSelected: onRouteSelected
        )
    }

    func makeSearchViewController(
        onRouteChosen: @escaping (LastRoute) -> Void,
        onBack: @escaping () -> Void
    ) -> UIViewController {
        let viewModel = SearchViewModel(
            searchPlacesUseCase: searchPlacesUseCase,
            searchLastRoutesUseCase: searchLastRoutesUseCase,
            recentSearchesUseCase: recentSearchesUseCase
        )
        viewModel.onRouteChosen = onRouteChosen
        viewModel.onBackRequested = onBack
        return SearchViewController(viewModel: viewModel)
    }
}
