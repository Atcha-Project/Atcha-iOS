import Foundation

/// 변경 판정 스트림. AlarmSyncEvents(성공 정보 replay-1)와 달리 **replay 없음** —
/// 과거 변경 알림이 재구독 시 다시 발화하면 안 된다.
public protocol AlarmChangeEvents: Sendable {
    func changes() -> AsyncStream<AlarmChangeVerdict>
}
