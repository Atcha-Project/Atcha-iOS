import Foundation

/// 알람 세션의 **단일 진실 원천**. 앱 안에 한 개만 존재한다.
///
/// `AlarmSessionSnapshot`이 서버 사실과 로컬 사실을 한 겹에 담아 "서버의 복제본"처럼
/// 보였던 것을, 성질이 다른 세 덩이로 나눈다. 이 분리가 중요한 이유는 각각의 **권위가
/// 다르기** 때문이다 — 충돌 시 서버가 이기는 값, 서버가 절대 주지 않는 값, 로컬만 아는
/// 수명이 섞여 있으면 "누가 이기는가"를 필드마다 따로 기억해야 한다.
public struct AlarmSession: Sendable, Equatable, Codable {
    /// 시각의 정본. refresh 결과와 충돌하면 **항상 이쪽이 이긴다**.
    public let server: AlarmInfo
    /// 서버가 주지 않는 값 — 로컬이 유일 원천이라 잃으면 복구할 수 없다.
    public let local: LocalFacts
    public let lifecycle: Lifecycle
    /// 마지막으로 서버에 확인된 시각. 신선도 스탬프("HH:mm 확인 기준")의 출처이고,
    /// 오프라인·재실행에서도 낡은 시각을 정직하게 보여주는 근거다.
    public let syncedAt: Date?

    /// refresh 응답에 없는 값들. `firstWalkSeconds`가 특히 중요하다 — 알람 발화 시각
    /// 계산에 필수인데 **등록 시점 경로에서만** 얻을 수 있다.
    public struct LocalFacts: Sendable, Equatable, Codable {
        /// 등록 시점 경로의 첫 도보 구간(초).
        public let firstWalkSeconds: Int?
        /// LA·카드 복원용 표시명 (예: "6411번 버스").
        public let routeDisplayName: String
        /// LA 재시작 시 아이콘 분기용.
        public let transportMode: TransportMode?

        public init(
            firstWalkSeconds: Int?,
            routeDisplayName: String,
            transportMode: TransportMode?
        ) {
            self.firstWalkSeconds = firstWalkSeconds
            self.routeDisplayName = routeDisplayName
            self.transportMode = transportMode
        }
    }

    /// 세션 수명. 이전에는 `acknowledged`·`expired` 2개 Bool이었고 `(true, true)` 조합이
    /// 표현 가능했는데 그 의미가 정의돼 있지 않았다.
    ///
    /// 하나로 합쳐도 동작이 보존되는 근거: `acknowledged`를 읽는 프로덕션 코드는 LA
    /// 재시작 게이트 한 곳뿐이고, 거기서 `expired`와 **함께** 검사해 둘 중 하나라도
    /// 참이면 결과가 "재시작 금지"로 같다. 따라서 `acknowledged → ended` 전이에서
    /// 잃는 정보가 없다.
    public enum Lifecycle: String, Sendable, Equatable, Codable {
        /// 살아 있는 세션. LA 재시작 대상.
        case active
        /// stopIntent("확인") 수신 — departed 소멸 예약이 이미 잡혀 있어 재시작 금지.
        case acknowledged
        /// 죽은 세션 톰스톤. **지우지 않고 남기는 이유**: 지워 버리면 다음 실행에서
        /// 같은 과거 세션의 refresh가 배너·재부착을 되살린다(2차 방어의 영속화).
        case ended
    }

    public init(
        server: AlarmInfo,
        local: LocalFacts,
        lifecycle: Lifecycle = .active,
        syncedAt: Date? = nil
    ) {
        self.server = server
        self.local = local
        self.lifecycle = lifecycle
        self.syncedAt = syncedAt
    }

    // MARK: - 파생 (저장 금지)

    /// 알람 발화 시각. **`firstWalkSeconds`를 읽는 유일한 지점**이다.
    ///
    /// 이전에는 스냅샷 → RefreshAlarmUseCase → AlarmSyncService → HomeViewModel 4곳이
    /// 각자 도보 초를 들고 `alarmFireDate`를 호출했다. 출처가 하나가 되면
    /// `AlarmTiming.alarmFireDate`의 "콜사이트가 도보 초 출처를 명시하게 강제한다"는
    /// 방어 장치가 타입으로 달성된다.
    public var fireDate: Date? {
        guard let departure = server.departureTime else { return nil }
        return AlarmTiming.alarmFireDate(
            departureTime: departure,
            firstWalkSeconds: local.firstWalkSeconds
        )
    }

    /// LA 재시작 대상인가. `active`만 해당한다.
    public var allowsActivityRestart: Bool { lifecycle == .active }

    public var isEnded: Bool { lifecycle == .ended }

    /// 출발 시각 + 유예를 지났는가. 판정 자체는 `AlarmTiming`의 순수 함수가 한다 —
    /// 여기서 다시 계산하지 않는다.
    public func hasPassedDeparture(now: Date) -> Bool {
        guard let departure = server.departureTime else { return false }
        return AlarmTiming.isSessionExpired(departureTime: departure, now: now)
    }

    // MARK: - 전이

    /// 서버 사실만 갈아끼운다. **같은 경로일 때만 로컬 사실을 보존**한다 — 다른 경로면
    /// 도보 초·표시명이 그 경로의 것이 아니므로 들고 가면 알람이 틀린 시각에 울린다.
    ///
    /// 이 규칙은 이전에 두 곳(`AlarmSyncService`의 스냅샷 병합, `RefreshAlarmUseCase`의
    /// routeId 비교)이 각자 판단하고 있었다.
    public func merging(server newServer: AlarmInfo, syncedAt: Date?) -> AlarmSession {
        let sameRoute = newServer.lastRouteId == server.lastRouteId
        return AlarmSession(
            server: newServer,
            local: sameRoute ? local : .empty,
            lifecycle: lifecycle,
            syncedAt: syncedAt ?? self.syncedAt
        )
    }

    public func with(lifecycle newLifecycle: Lifecycle) -> AlarmSession {
        AlarmSession(
            server: server,
            local: local,
            lifecycle: newLifecycle,
            syncedAt: syncedAt
        )
    }

    public func with(syncedAt newSyncedAt: Date?) -> AlarmSession {
        AlarmSession(
            server: server,
            local: local,
            lifecycle: lifecycle,
            syncedAt: newSyncedAt ?? syncedAt
        )
    }
}

public extension AlarmSession.LocalFacts {
    /// 로컬 사실을 모르는 세션 — 서버 refresh로만 발견한 경우(재실행 후 등록 기록이
    /// 없거나 다른 경로로 바뀐 경우). 도보 초가 없으면 알람은 버퍼만 적용된 시각에
    /// 울리므로, 다음 등록이 이 값을 채워야 한다.
    static var empty: Self {
        .init(firstWalkSeconds: nil, routeDisplayName: "", transportMode: nil)
    }
}

/// 세션 영속화 포트 — 구현(저장 백엔드)은 App에 둔다.
/// 디코딩 실패는 구현이 nil로 무해화한다(자가치유 — 다음 save가 덮어쓴다).
public protocol AlarmSessionStoring: Sendable {
    func loadSession() async -> AlarmSession?
    func saveSession(_ session: AlarmSession) async
    func clearSession() async
}
