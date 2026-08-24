import Foundation

/// 동기화 성공 방출값(Phase 16) — info에 "언제 서버로 확인했는가"를 동봉한다.
/// checkedAt이 신선도 스탬프("HH:mm 확인 기준")의 유일한 원천이다 — 구독자(홈)가
/// 수신 시각으로 찍으면 스냅샷 시딩 복원값이 "지금 확인됨"으로 둔갑하므로 금지.
public struct AlarmSyncUpdate: Sendable, Equatable {
    public let info: AlarmInfo
    /// 서버 확인 시각. 스냅샷 시딩 복원이면 직전 세션의 마지막 확인 시각(스냅샷의
    /// syncedAt), 그것도 없으면 nil — nil이면 스탬프를 표시하지 않는다(정직한 기본값).
    public let checkedAt: Date?

    public init(info: AlarmInfo, checkedAt: Date?) {
        self.info = info
        self.checkedAt = checkedAt
    }
}

/// 알람 동기화 결과 포트 — 발행 주체는 App의 AlarmSyncService(앱 시작·포그라운드
/// 복귀·사일런트 푸시·수동 갱신 4경로를 RefreshAlarmUseCase 한 곳으로 모으는 유일한 호출자).
/// 실패는 흘리지 않는다 — 구독자는 성공 결과만 받고, 실패 시 기존 상태를 유지한다
/// (실패의 표면은 신선도 스탬프가 낡은 시각을 유지하는 것뿐 — 원칙 3).
public protocol AlarmSyncEvents: Sendable {
    /// 구독자마다 독립 스트림. 구독 시 마지막 동기화 결과가 있으면 즉시 방출한다
    /// (구독 전에 끝난 앱 시작 동기화를 놓치지 않도록).
    func updates() -> AsyncStream<AlarmSyncUpdate>
}
