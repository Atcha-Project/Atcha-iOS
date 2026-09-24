import CoreCoordinator
import Domain
import SettingsFeatureInterface
import UIKit

/// Assembles the Settings feature's screens. Coordinators own flow only;
/// screen/ViewModel assembly stays here so adding screens never bloats
/// coordinator initializers.
public final class SettingsDIContainer: SettingsCoordinatorBuildable {
    private let userRepository: any UserRepository
    private let logoutUseCase: any LogoutUseCase
    private let withdrawUseCase: any WithdrawUseCase
    private let updateHomeAddressUseCase: any UpdateHomeAddressUseCase
    private let placeRepository: any PlaceRepository
    private let locationService: any LocationService
    private let checkAppUpdateUseCase: (any CheckAppUpdateUseCase)?
    private let currentVersion: String
    private let appStoreURL: URL?

    public init(
        userRepository: any UserRepository,
        logoutUseCase: any LogoutUseCase,
        withdrawUseCase: any WithdrawUseCase,
        updateHomeAddressUseCase: any UpdateHomeAddressUseCase,
        placeRepository: any PlaceRepository,
        locationService: any LocationService,
        checkAppUpdateUseCase: (any CheckAppUpdateUseCase)? = nil,
        currentVersion: String,
        appStoreURL: URL? = nil
    ) {
        self.userRepository = userRepository
        self.logoutUseCase = logoutUseCase
        self.withdrawUseCase = withdrawUseCase
        self.updateHomeAddressUseCase = updateHomeAddressUseCase
        self.placeRepository = placeRepository
        self.locationService = locationService
        self.checkAppUpdateUseCase = checkAppUpdateUseCase
        self.currentVersion = currentVersion
        self.appStoreURL = appStoreURL
    }

    public func makeSettingsCoordinator(navigationController: UINavigationController) -> any Coordinator {
        SettingsCoordinator(navigationController: navigationController, container: self)
    }

    func makeSettingsScreen() -> (UIViewController, SettingsViewModel) {
        let viewModel = SettingsViewModel(
            userRepository: userRepository,
            logoutUseCase: logoutUseCase,
            checkAppUpdateUseCase: checkAppUpdateUseCase,
            currentVersion: currentVersion,
            appStoreURL: appStoreURL
        )
        return (SettingsViewController(viewModel: viewModel), viewModel)
    }

    func makeWithdrawViewController() -> UIViewController {
        WithdrawViewController(viewModel: WithdrawViewModel(withdrawUseCase: withdrawUseCase))
    }

    func makeHomeAddressViewController(onSaved: @escaping () -> Void) -> UIViewController {
        let viewModel = HomeAddressViewModel(
            placeRepository: placeRepository,
            locationService: locationService,
            updateHomeAddressUseCase: updateHomeAddressUseCase
        )
        viewModel.onSaved = onSaved
        return HomeAddressViewController(viewModel: viewModel)
    }
}
