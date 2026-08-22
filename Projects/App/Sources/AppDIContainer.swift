import AtchaData
import CoreAlarm
import CoreAuth
import CoreNetwork
import CoreStorage
import Domain
import Foundation
import HomeFeature
import HomeFeatureInterface
import SearchFeature
import SearchFeatureInterface

/// Composition root — the only place that sees concrete Data/Network types.
/// Presentation modules depend on Domain protocols only.
final class AppDIContainer {
    private let networkClient: any NetworkClient
    let authSessionManager: AuthSessionManager

    init() {
        #if DEV
        // 검수용 임시 우회: 실서버(미확정 #1·#2)가 죽어 있어도 기본 60초 타임아웃 대기로
        // 시연이 멈추지 않게 짧은 타임아웃을 쓴다. DevDemoFallbacks와 함께 제거한다.
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.timeoutIntervalForRequest = 3
        sessionConfiguration.timeoutIntervalForResource = 5
        let baseClient = URLSessionNetworkClient(
            baseURL: AppEnvironment.current.apiBaseURL,
            session: URLSession(configuration: sessionConfiguration)
        )
        #else
        let baseClient = URLSessionNetworkClient(
            baseURL: AppEnvironment.current.apiBaseURL
        )
        #endif
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
        #if DEV
        // 검수용 임시 우회 — 실서버(미확정 #1·#2) 부재 시에만 데모 데이터로 폴백.
        // 실서버 확정 시 이 블록과 DevDemoFallbacks.swift를 제거한다.
        let placeRepository: any PlaceRepository = DevDemoFallbackPlaceRepository(
            base: PlaceRepositoryImpl(networkClient: networkClient)
        )
        let lastRouteRepository: any LastRouteRepository = DevDemoFallbackLastRouteRepository(
            base: LastRouteRepositoryImpl(networkClient: networkClient)
        )
        let alarmRepository: any AlarmRepository = DevDemoTolerantAlarmRepository(
            base: AlarmRepositoryImpl(networkClient: networkClient)
        )
        #else
        let placeRepository: any PlaceRepository = PlaceRepositoryImpl(networkClient: networkClient)
        let lastRouteRepository: any LastRouteRepository = LastRouteRepositoryImpl(networkClient: networkClient)
        let alarmRepository: any AlarmRepository = AlarmRepositoryImpl(networkClient: networkClient)
        #endif
        let recentSearchRepository = RecentSearchRepositoryImpl(store: UserDefaultsKeyValueStore())

        // 디바이스 포트 어댑터 — CoreLocation/AlarmKit을 아는 곳은 App의 어댑터뿐.
        let locationService = CoreLocationServiceAdapter()
        let getCurrentLocation: any GetCurrentLocationUseCase =
            DefaultGetCurrentLocationUseCase(locationService: locationService)
        let alarmScheduler = CoreAlarmSchedulerAdapter()

        let searchContainer = SearchDIContainer(
            searchPlacesUseCase: DefaultSearchPlacesUseCase(repository: placeRepository),
            searchLastRoutesUseCase: DefaultSearchLastRoutesUseCase(repository: lastRouteRepository),
            recentSearchesUseCase: DefaultRecentSearchesUseCase(repository: recentSearchRepository),
            getCurrentLocationUseCase: getCurrentLocation
        )

        return HomeDIContainer(
            getCurrentLocationUseCase: getCurrentLocation,
            reverseGeocodeUseCase: DefaultReverseGeocodeUseCase(repository: placeRepository),
            registerAlarmUseCase: DefaultRegisterAlarmUseCase(
                repository: alarmRepository,
                scheduler: alarmScheduler
            ),
            cancelAlarmUseCase: DefaultCancelAlarmUseCase(
                repository: alarmRepository,
                scheduler: alarmScheduler
            ),
            refreshAlarmUseCase: DefaultRefreshAlarmUseCase(
                repository: alarmRepository,
                scheduler: alarmScheduler
            ),
            searchCoordinatorBuildable: searchContainer
        )
    }
}
