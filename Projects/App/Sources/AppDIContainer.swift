import AtchaData
import CoreNetwork
import Domain
import HomeFeature
import HomeFeatureInterface

/// Composition root — the only place that sees concrete Data/Network types.
/// Presentation modules depend on Domain protocols only.
final class AppDIContainer {
    private let networkClient: any NetworkClient

    init() {
        self.networkClient = URLSessionNetworkClient(
            baseURL: AppEnvironment.current.apiBaseURL
        )
    }

    func makeHomeDIContainer() -> any HomeCoordinatorBuildable {
        let repository: any HomeRepository = HomeRepositoryImpl(networkClient: networkClient)
        let fetchHome: any FetchHomeUseCase = DefaultFetchHomeUseCase(repository: repository)
        return HomeDIContainer(fetchHomeUseCase: fetchHome)
    }
}
