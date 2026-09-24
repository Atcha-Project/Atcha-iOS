import AuthFeatureInterface
import CoreCoordinator
import Domain
import UIKit

/// Assembles the Auth feature's screens. Coordinators own flow only;
/// screen/ViewModel assembly stays here.
public final class AuthDIContainer: AuthCoordinatorBuildable {
    private let signInUseCase: any SignInUseCase

    public init(signInUseCase: any SignInUseCase) {
        self.signInUseCase = signInUseCase
    }

    public func makeLoginCoordinator(
        navigationController: UINavigationController,
        onAuthenticated: @escaping () -> Void
    ) -> any Coordinator {
        LoginCoordinator(
            navigationController: navigationController,
            container: self,
            onAuthenticated: onAuthenticated
        )
    }

    func makeLoginViewController(onAuthenticated: @escaping () -> Void) -> LoginViewController {
        let viewModel = LoginViewModel(signInUseCase: signInUseCase)
        viewModel.onAuthenticated = onAuthenticated
        return LoginViewController(viewModel: viewModel)
    }
}
