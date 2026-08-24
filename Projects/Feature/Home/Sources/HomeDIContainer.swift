import CoreCoordinator
import Domain
import HomeFeatureInterface
import SearchFeatureInterface
import UIKit

/// Assembles the Home feature's screens. Coordinators own flow only;
/// screen/ViewModel assembly stays here so adding screens never bloats
/// coordinator initializers.
public final class HomeDIContainer: HomeCoordinatorBuildable {
    private let getCurrentLocationUseCase: any GetCurrentLocationUseCase
    private let reverseGeocodeUseCase: any ReverseGeocodeUseCase
    private let registerAlarmUseCase: any RegisterAlarmUseCase
    private let cancelAlarmUseCase: any CancelAlarmUseCase
    private let observeAlarmUseCase: any ObserveAlarmUseCase
    private let observeAlarmChangeUseCase: any ObserveAlarmChangeUseCase
    private let requestAlarmSyncUseCase: any RequestAlarmSyncUseCase
    private let getLastRouteDetailUseCase: any GetLastRouteDetailUseCase
    private let searchCoordinatorBuildable: any SearchCoordinatorBuildable

    public init(
        getCurrentLocationUseCase: any GetCurrentLocationUseCase,
        reverseGeocodeUseCase: any ReverseGeocodeUseCase,
        registerAlarmUseCase: any RegisterAlarmUseCase,
        cancelAlarmUseCase: any CancelAlarmUseCase,
        observeAlarmUseCase: any ObserveAlarmUseCase,
        observeAlarmChangeUseCase: any ObserveAlarmChangeUseCase,
        requestAlarmSyncUseCase: any RequestAlarmSyncUseCase,
        getLastRouteDetailUseCase: any GetLastRouteDetailUseCase,
        searchCoordinatorBuildable: any SearchCoordinatorBuildable
    ) {
        self.getCurrentLocationUseCase = getCurrentLocationUseCase
        self.reverseGeocodeUseCase = reverseGeocodeUseCase
        self.registerAlarmUseCase = registerAlarmUseCase
        self.cancelAlarmUseCase = cancelAlarmUseCase
        self.observeAlarmUseCase = observeAlarmUseCase
        self.observeAlarmChangeUseCase = observeAlarmChangeUseCase
        self.requestAlarmSyncUseCase = requestAlarmSyncUseCase
        self.getLastRouteDetailUseCase = getLastRouteDetailUseCase
        self.searchCoordinatorBuildable = searchCoordinatorBuildable
    }

    public func makeHomeCoordinator(navigationController: UINavigationController) -> any Coordinator {
        HomeCoordinator(navigationController: navigationController, container: self)
    }

    func makeHomeViewController(
        onSearchRequested: @escaping (_ onRouteSelected: @escaping (LastRoute) -> Void) -> Void
    ) -> UIViewController {
        let viewModel = HomeViewModel(
            getCurrentLocationUseCase: getCurrentLocationUseCase,
            reverseGeocodeUseCase: reverseGeocodeUseCase,
            registerAlarmUseCase: registerAlarmUseCase,
            cancelAlarmUseCase: cancelAlarmUseCase,
            observeAlarmUseCase: observeAlarmUseCase,
            observeAlarmChangeUseCase: observeAlarmChangeUseCase,
            requestAlarmSyncUseCase: requestAlarmSyncUseCase,
            getLastRouteDetailUseCase: getLastRouteDetailUseCase
        )
        viewModel.onSearchRequested = onSearchRequested
        return HomeViewController(viewModel: viewModel)
    }

    func makeSearchCoordinator(
        navigationController: UINavigationController,
        onRouteSelected: @escaping (LastRoute) -> Void
    ) -> any Coordinator {
        searchCoordinatorBuildable.makeSearchCoordinator(
            navigationController: navigationController,
            onRouteSelected: onRouteSelected
        )
    }
}
