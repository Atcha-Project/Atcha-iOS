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
    private let getCurrentLocationUseCase: (any GetCurrentLocationUseCase)?

    public init(
        searchPlacesUseCase: any SearchPlacesUseCase,
        searchLastRoutesUseCase: any SearchLastRoutesUseCase,
        recentSearchesUseCase: any RecentSearchesUseCase,
        getCurrentLocationUseCase: (any GetCurrentLocationUseCase)? = nil
    ) {
        self.searchPlacesUseCase = searchPlacesUseCase
        self.searchLastRoutesUseCase = searchLastRoutesUseCase
        self.recentSearchesUseCase = recentSearchesUseCase
        self.getCurrentLocationUseCase = getCurrentLocationUseCase
    }

    public func makeSearchCoordinator(
        navigationController: UINavigationController,
        initialField: SearchEntryField,
        onRouteSelected: @escaping (LastRoute, Place) -> Void
    ) -> any Coordinator {
        SearchCoordinator(
            navigationController: navigationController,
            container: self,
            initialField: initialField,
            onRouteSelected: onRouteSelected
        )
    }

    func makeSearchViewController(
        initialField: SearchEntryField,
        onRouteChosen: @escaping (LastRoute, Place) -> Void,
        onBack: @escaping () -> Void
    ) -> UIViewController {
        let viewModel = SearchViewModel(
            searchPlacesUseCase: searchPlacesUseCase,
            searchLastRoutesUseCase: searchLastRoutesUseCase,
            recentSearchesUseCase: recentSearchesUseCase,
            getCurrentLocationUseCase: getCurrentLocationUseCase,
            initialField: initialField
        )
        viewModel.onRouteChosen = onRouteChosen
        viewModel.onBackRequested = onBack
        return SearchViewController(viewModel: viewModel)
    }
}
