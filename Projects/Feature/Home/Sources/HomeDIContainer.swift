import CoreCoordinator
import Domain
import HomeFeatureInterface
import SearchFeatureInterface
import SettingsFeatureInterface
import UIKit

/// Assembles the Home feature's screens. Coordinators own flow only;
/// screen/ViewModel assembly stays here so adding screens never bloats
/// coordinator initializers.
public final class HomeDIContainer: HomeCoordinatorBuildable {
    private let locationService: any LocationService
    private let placeRepository: any PlaceRepository
    private let registerAlarmUseCase: any RegisterAlarmUseCase
    private let cancelAlarmUseCase: any CancelAlarmUseCase
    private let alarmSyncEvents: any AlarmSyncEvents
    private let alarmChangeEvents: any AlarmChangeEvents
    private let alarmSyncRequesting: any AlarmSyncRequesting
    private let lastRouteRepository: any LastRouteRepository
    private let searchLastRoutesUseCase: any SearchLastRoutesUseCase
    private let recentSearchRepository: any RecentSearchRepository
    private let searchCoordinatorBuildable: any SearchCoordinatorBuildable
    /// nil이면 톱니바퀴가 아무 일도 하지 않는다(Example 구성 호환).
    private let settingsCoordinatorBuildable: (any SettingsCoordinatorBuildable)?

    public init(
        locationService: any LocationService,
        placeRepository: any PlaceRepository,
        registerAlarmUseCase: any RegisterAlarmUseCase,
        cancelAlarmUseCase: any CancelAlarmUseCase,
        alarmSyncEvents: any AlarmSyncEvents,
        alarmChangeEvents: any AlarmChangeEvents,
        alarmSyncRequesting: any AlarmSyncRequesting,
        lastRouteRepository: any LastRouteRepository,
        searchLastRoutesUseCase: any SearchLastRoutesUseCase,
        recentSearchRepository: any RecentSearchRepository,
        searchCoordinatorBuildable: any SearchCoordinatorBuildable,
        settingsCoordinatorBuildable: (any SettingsCoordinatorBuildable)? = nil
    ) {
        self.locationService = locationService
        self.placeRepository = placeRepository
        self.registerAlarmUseCase = registerAlarmUseCase
        self.cancelAlarmUseCase = cancelAlarmUseCase
        self.alarmSyncEvents = alarmSyncEvents
        self.alarmChangeEvents = alarmChangeEvents
        self.alarmSyncRequesting = alarmSyncRequesting
        self.lastRouteRepository = lastRouteRepository
        self.searchLastRoutesUseCase = searchLastRoutesUseCase
        self.recentSearchRepository = recentSearchRepository
        self.searchCoordinatorBuildable = searchCoordinatorBuildable
        self.settingsCoordinatorBuildable = settingsCoordinatorBuildable
    }

    public func makeHomeCoordinator(navigationController: UINavigationController) -> any Coordinator {
        HomeCoordinator(navigationController: navigationController, container: self)
    }

    func makeHomeViewController(
        onSearchRequested: @escaping (
            _ initialField: SearchEntryField,
            _ onRouteSelected: @escaping (LastRoute, Place) -> Void
        ) -> Void,
        onSettingsRequested: @escaping () -> Void
    ) -> UIViewController {
        let viewModel = HomeViewModel(
            locationService: locationService,
            placeRepository: placeRepository,
            registerAlarmUseCase: registerAlarmUseCase,
            cancelAlarmUseCase: cancelAlarmUseCase,
            alarmSyncEvents: alarmSyncEvents,
            alarmChangeEvents: alarmChangeEvents,
            alarmSyncRequesting: alarmSyncRequesting,
            lastRouteRepository: lastRouteRepository,
            searchLastRoutesUseCase: searchLastRoutesUseCase,
            recentSearchRepository: recentSearchRepository
        )
        viewModel.onSearchRequested = onSearchRequested
        viewModel.onSettingsRequested = onSettingsRequested
        return HomeViewController(viewModel: viewModel)
    }

    func makeSearchCoordinator(
        navigationController: UINavigationController,
        initialField: SearchEntryField,
        onRouteSelected: @escaping (LastRoute, Place) -> Void
    ) -> any Coordinator {
        searchCoordinatorBuildable.makeSearchCoordinator(
            navigationController: navigationController,
            initialField: initialField,
            onRouteSelected: onRouteSelected
        )
    }

    func makeSettingsCoordinator(navigationController: UINavigationController) -> (any Coordinator)? {
        settingsCoordinatorBuildable?.makeSettingsCoordinator(navigationController: navigationController)
    }
}
