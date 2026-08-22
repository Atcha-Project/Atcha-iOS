import Foundation

/// 알람 동기화 결과 포트 — 발행 주체는 App의 AlarmSyncService(앱 시작·포그라운드
/// 복귀·사일런트 푸시 3경로를 RefreshAlarmUseCase 한 곳으로 모으는 유일한 호출자).
/// 실패는 흘리지 않는다 — 구독자는 성공 결과만 받고, 실패 시 기존 상태를 유지한다.
public protocol AlarmSyncEvents: Sendable {
    /// 구독자마다 독립 스트림. 구독 시 마지막 동기화 결과가 있으면 즉시 방출한다
    /// (구독 전에 끝난 앱 시작 동기화를 놓치지 않도록).
    func updates() -> AsyncStream<AlarmInfo>
}
