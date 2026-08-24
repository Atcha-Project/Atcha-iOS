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

    // 알람 스택은 1회 생성해 공유한다 — AlarmSyncService(갱신 일원화)와
    // 홈의 등록/해제 UseCase가 같은 리포지토리·스케줄러를 봐야 한다.
    private let alarmRepository: any AlarmRepository
    private let placeRepository: any PlaceRepository
    private let lastRouteRepository: any LastRouteRepository
    private let alarmScheduler: any AlarmScheduler
    // LA도 알람 세션과 수명을 같이하므로 1회 생성해 공유한다 — dismiss 기록이 세션 단위여야 한다.
    private let liveActivityPort: any LastTrainActivityPort
    // 로컬 노티도 1회 생성 공유 — 권한 요청 훅(등록 UseCase)과 dismiss 폴백 발송(AlarmSyncService)이
    // 같은 요청 이력을 봐야 한다. UNUserNotificationCenter를 아는 곳은 이 어댑터뿐.
    private let localNotificationPort: any LocalNotificationPort
    let alarmSyncService: AlarmSyncService
    /// Phase 13 발화 이후 세션 수명 — stopIntent(AlarmAcknowledgeIntent)가 조합 루트를
    /// 거쳐 도달하는 지점. AppDelegate 경유로 인텐트 perform()이 접근한다.
    let alarmSessionLifecycle: AlarmSessionLifecycleService
    #if DEV
    /// DEV 플로팅 디버그 메뉴가 dismiss 기록 강제 토글에 접근하는 유일한 통로 (Phase 12 검수).
    let devLiveActivityAdapter: LastTrainLiveActivityAdapter
    #endif

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
        let networkClient = AuthenticatedNetworkClient(
            base: baseClient,
            sessionManager: sessionManager
        )
        self.networkClient = networkClient

        #if DEV
        // 검수용 임시 우회 — 실서버(미확정 #1·#2) 부재 시에만 데모 데이터로 폴백.
        // 실서버 확정 시 이 블록과 DevDemoFallbacks.swift를 제거한다.
        self.placeRepository = DevDemoFallbackPlaceRepository(
            base: PlaceRepositoryImpl(networkClient: networkClient)
        )
        self.lastRouteRepository = DevDemoFallbackLastRouteRepository(
            base: LastRouteRepositoryImpl(networkClient: networkClient)
        )
        self.alarmRepository = DevDemoTolerantAlarmRepository(
            base: AlarmRepositoryImpl(networkClient: networkClient)
        )
        #else
        self.placeRepository = PlaceRepositoryImpl(networkClient: networkClient)
        self.lastRouteRepository = LastRouteRepositoryImpl(networkClient: networkClient)
        self.alarmRepository = AlarmRepositoryImpl(networkClient: networkClient)
        #endif

        // 디바이스 포트 어댑터 — CoreLocation/AlarmKit/ActivityKit을 아는 곳은 App의 어댑터뿐.
        // Phase 13: stop 버튼("확인")에 발화 확인 인텐트를 싣는다 — 인텐트 타입은 App 소유,
        // CoreAlarm은 인스턴스를 전달만 한다(주입 실패 시 인텐트 없이 스케줄되는 폴백 유지).
        let alarmScheduler = CoreAlarmSchedulerAdapter(
            scheduling: AlarmKitScheduler(stopIntent: AlarmAcknowledgeIntent())
        )
        self.alarmScheduler = alarmScheduler
        // 구체 어댑터로 들고 있다가 세 얼굴로 나눠 준다 — Domain 포트(등록/해제 UseCase),
        // App 내부 변경 표출 경로(LastTrainChangeAlerting, Phase 11 훅),
        // 발화 확인 경로(LastTrainDepartureEnding, Phase 13).
        let liveActivityAdapter = LastTrainLiveActivityAdapter()
        self.liveActivityPort = liveActivityAdapter
        self.alarmSessionLifecycle = AlarmSessionLifecycleService(liveActivity: liveActivityAdapter)
        #if DEV
        self.devLiveActivityAdapter = liveActivityAdapter
        #endif
        let localNotificationAdapter = LocalNotificationAdapter()
        self.localNotificationPort = localNotificationAdapter
        self.alarmSyncService = AlarmSyncService(
            refreshAlarmUseCase: DefaultRefreshAlarmUseCase(
                repository: alarmRepository,
                scheduler: alarmScheduler
            ),
            evaluateChangeUseCase: DefaultEvaluateAlarmChangeUseCase(),
            liveActivity: liveActivityAdapter,
            localNotification: localNotificationAdapter,
            alarmScheduler: alarmScheduler
        )
    }

    func makeHomeDIContainer() -> any HomeCoordinatorBuildable {
        let recentSearchRepository = RecentSearchRepositoryImpl(store: UserDefaultsKeyValueStore())
        let locationService = CoreLocationServiceAdapter()
        let getCurrentLocation: any GetCurrentLocationUseCase =
            DefaultGetCurrentLocationUseCase(locationService: locationService)

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
                scheduler: alarmScheduler,
                activityPort: liveActivityPort,
                // 알림 권한 요청의 유일한 시점(등록 성공 직후) — UseCase 내부 훅이 호출한다.
                notificationPort: localNotificationPort
            ),
            cancelAlarmUseCase: DefaultCancelAlarmUseCase(
                repository: alarmRepository,
                scheduler: alarmScheduler,
                activityPort: liveActivityPort
            ),
            observeAlarmUseCase: DefaultObserveAlarmUseCase(events: alarmSyncService),
            observeAlarmChangeUseCase: DefaultObserveAlarmChangeUseCase(events: alarmSyncService),
            searchCoordinatorBuildable: searchContainer
        )
    }
}
