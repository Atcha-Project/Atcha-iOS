import Foundation

/// 알람 세션의 재실행 브리지 (Phase 14) — 앱 프로세스 수명과 알람 세션 수명을 분리한다.
/// 정본은 여전히 서버(refresh)다: 스냅샷만으로 알람을 새로 만들지 않고, 서버 결과와
/// 충돌하면 항상 서버가 이긴다. 기록 시점: 등록 성공·sync 성공 시 save,
/// 취소·서버 sessionEnded 시 clear, 로컬 만료 확정 시 expired=true 톰스톤
/// (재실행 후에도 같은 과거 세션의 refresh가 배너를 되살리지 못하게 하는 2차 방어).
public struct AlarmSessionSnapshot: Sendable, Equatable, Codable {
    public let info: AlarmInfo
    /// 등록 시점 경로의 첫 도보 구간(초) — 알람 기준 시각 계산용 (없으면 nil).
    public let firstWalkSeconds: Int?
    /// LA·카드 복원용 표시명 (예: "6411번 버스").
    public let routeDisplayName: String
    /// 탑승 수단 — LA 재시작 시 아이콘 분기용 (확정 결정: 스냅샷 = 표시명·수단 포함).
    public let transportMode: TransportMode?
    /// stopIntent 확인 기록 (Phase 13 연동) — 확인된 세션은 LA를 재시작하지 않는다
    /// (departed 소멸 예약이 이미 잡혀 있다).
    public let acknowledged: Bool
    /// 로컬 만료 기록 (Phase 13 연동) — true면 죽은 세션 톰스톤.
    public let expired: Bool
    /// 이 세션 값이 마지막으로 서버로 확인된 시각(Phase 16) — 등록 성공·sync 성공 시
    /// 갱신된다. 재실행 시딩이 이 값을 날라 신선도 스탬프("HH:mm 확인 기준")가 재실행·
    /// 오프라인에서도 마지막 확인 시각을 정직하게 유지한다. 구 스냅샷은 nil로 디코딩된다.
    public let syncedAt: Date?

    public init(
        info: AlarmInfo,
        firstWalkSeconds: Int?,
        routeDisplayName: String,
        transportMode: TransportMode?,
        acknowledged: Bool,
        expired: Bool,
        syncedAt: Date? = nil
    ) {
        self.info = info
        self.firstWalkSeconds = firstWalkSeconds
        self.routeDisplayName = routeDisplayName
        self.transportMode = transportMode
        self.acknowledged = acknowledged
        self.expired = expired
        self.syncedAt = syncedAt
    }

    /// 세션 사실(도보·표시명·수단)은 유지하고 기록 필드만 바꾼 사본.
    /// syncedAt은 명시할 때만 갱신된다 — 만료 톰스톤 전환 등은 마지막 확인 시각을 보존한다.
    public func updating(
        info: AlarmInfo? = nil,
        acknowledged: Bool? = nil,
        expired: Bool? = nil,
        syncedAt: Date? = nil
    ) -> AlarmSessionSnapshot {
        AlarmSessionSnapshot(
            info: info ?? self.info,
            firstWalkSeconds: firstWalkSeconds,
            routeDisplayName: routeDisplayName,
            transportMode: transportMode,
            acknowledged: acknowledged ?? self.acknowledged,
            expired: expired ?? self.expired,
            syncedAt: syncedAt ?? self.syncedAt
        )
    }
}

/// 스냅샷 영속화 포트 — 어댑터(UserDefaults 백엔드)는 App에 둔다.
/// 디코딩 실패는 어댑터가 nil로 무해화한다(자가치유 — 다음 save가 덮어쓴다).
public protocol AlarmSessionSnapshotStore: Sendable {
    func load() async -> AlarmSessionSnapshot?
    func save(_ snapshot: AlarmSessionSnapshot) async
    func clear() async
}
