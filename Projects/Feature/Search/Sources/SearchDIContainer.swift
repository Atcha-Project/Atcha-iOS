import CoreCoordinator
import Domain
import SearchFeatureInterface
import UIKit

/// Assembles the Search feature's screens. Coordinators own flow only;
/// screen/ViewModel assembly stays here so adding screens never bloats
/// coordinator initializers.
public final class SearchDIContainer: SearchCoordinatorBuildable {
    private let placeRepository: any PlaceRepository
    private let searchLastRoutesUseCase: any SearchLastRoutesUseCase
    private let recentSearchRepository: any RecentSearchRepository
    private let locationService: (any LocationService)?

    public init(
        placeRepository: any PlaceRepository,
        searchLastRoutesUseCase: any SearchLastRoutesUseCase,
        recentSearchRepository: any RecentSearchRepository,
        locationService: (any LocationService)? = nil
    ) {
        self.placeRepository = placeRepository
        self.searchLastRoutesUseCase = searchLastRoutesUseCase
        self.recentSearchRepository = recentSearchRepository
        self.locationService = locationService
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
            placeRepository: placeRepository,
            searchLastRoutesUseCase: searchLastRoutesUseCase,
            recentSearchRepository: recentSearchRepository,
            locationService: locationService,
            initialField: initialField
        )
        viewModel.onRouteChosen = onRouteChosen
        viewModel.onBackRequested = onBack
        return SearchViewController(viewModel: viewModel)
    }
}
