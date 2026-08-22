import AtchaData
import CoreAuth
import CoreNetwork
import CoreStorage
import Domain
import HomeFeature
import HomeFeatureInterface

/// Composition root — the only place that sees concrete Data/Network types.
/// Presentation modules depend on Domain protocols only.
final class AppDIContainer {
    private let networkClient: any NetworkClient
    let authSessionManager: AuthSessionManager

    init() {
        let baseClient = URLSessionNetworkClient(
            baseURL: AppEnvironment.current.apiBaseURL
        )
        let sessionManager = AuthSessionManager(
            tokenStore: TokenStore(store: KeychainStore()),
            // The plain client, not the decorator — reissue must never recurse
            // into the 401-recovery path.
            networkClient: baseClient,
            // 미확정 입력 #2: swap in the real issuer here once the anonymous
            // issuance endpoint spec is confirmed.
            issuer: UnconfiguredAnonymousSessionIssuer()
        )
        self.authSessionManager = sessionManager
        self.networkClient = AuthenticatedNetworkClient(
            base: baseClient,
            sessionManager: sessionManager
        )
    }

    func makeHomeDIContainer() -> any HomeCoordinatorBuildable {
        let repository: any HomeRepository = HomeRepositoryImpl(networkClient: networkClient)
        let fetchHome: any FetchHomeUseCase = DefaultFetchHomeUseCase(repository: repository)
        return HomeDIContainer(fetchHomeUseCase: fetchHome)
    }
}
