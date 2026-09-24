import CoreCoordinator
import Domain
import SettingsFeatureInterface
import UIKit

/// Assembles the Settings feature's screens. Coordinators own flow only;
/// screen/ViewModel assembly stays here so adding screens never bloats
/// coordinator initializers.
public final class SettingsDIContainer: SettingsCoordinatorBuildable {
    private let getUserProfileUseCase: any GetUserProfileUseCase
    private let logoutUseCase: any LogoutUseCase
    private let withdrawUseCase: any WithdrawUseCase
    private let updateHomeAddressUseCase: any UpdateHomeAddressUseCase
    private let searchPlacesUseCase: any SearchPlacesUseCase
    private let getCurrentLocationUseCase: any GetCurrentLocationUseCase
    private let reverseGeocodeUseCase: any ReverseGeocodeUseCase
    private let checkAppUpdateUseCase: (any CheckAppUpdateUseCase)?
    private let currentVersion: String
    private let appStoreURL: URL?

    public init(
        getUserProfileUseCase: any GetUserProfileUseCase,
        logoutUseCase: any LogoutUseCase,
        withdrawUseCase: any WithdrawUseCase,
        updateHomeAddressUseCase: any UpdateHomeAddressUseCase,
        searchPlacesUseCase: any SearchPlacesUseCase,
        getCurrentLocationUseCase: any GetCurrentLocationUseCase,
        reverseGeocodeUseCase: any ReverseGeocodeUseCase,
        checkAppUpdateUseCase: (any CheckAppUpdateUseCase)? = nil,
        currentVersion: String,
        appStoreURL: URL? = nil
    ) {
        self.getUserProfileUseCase = getUserProfileUseCase
        self.logoutUseCase = logoutUseCase
        self.withdrawUseCase = withdrawUseCase
        self.updateHomeAddressUseCase = updateHomeAddressUseCase
        self.searchPlacesUseCase = searchPlacesUseCase
        self.getCurrentLocationUseCase = getCurrentLocationUseCase
        self.reverseGeocodeUseCase = reverseGeocodeUseCase
        self.checkAppUpdateUseCase = checkAppUpdateUseCase
        self.currentVersion = currentVersion
        self.appStoreURL = appStoreURL
    }

    public func makeSettingsCoordinator(navigationController: UINavigationController) -> any Coordinator {
        SettingsCoordinator(navigationController: navigationController, container: self)
    }

    func makeSettingsScreen() -> (UIViewController, SettingsViewModel) {
        let viewModel = SettingsViewModel(
            getUserProfileUseCase: getUserProfileUseCase,
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
            searchPlacesUseCase: searchPlacesUseCase,
            getCurrentLocationUseCase: getCurrentLocationUseCase,
            reverseGeocodeUseCase: reverseGeocodeUseCase,
            updateHomeAddressUseCase: updateHomeAddressUseCase
        )
        viewModel.onSaved = onSaved
        return HomeAddressViewController(viewModel: viewModel)
    }
}
