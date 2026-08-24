import Foundation

/// 수동 동기화 요청 포트(Phase 16) — 구현은 App의 AlarmSyncService(4번째 트리거).
/// 홈 pull-to-refresh가 유일한 호출자다 — 새 표출 채널을 만들지 않고, 결과는
/// AlarmSyncEvents.updates() 스트림으로만 흐른다(실패 무음 정책 공유).
public protocol AlarmSyncRequesting: Sendable {
    /// 동기화 1회를 요청하고 완료까지 기다린다. 진행 중 동기화가 있으면 합류한다
    /// (당김·포그라운드 복귀가 겹쳐도 refresh는 1회). 실패를 던지지 않는다.
    func syncNow() async
}
