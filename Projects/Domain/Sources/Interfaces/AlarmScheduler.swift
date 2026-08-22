import Foundation

/// 디바이스 알람 포트 — 어댑터 구현은 Phase 7(CoreAlarm)에서 App에 둔다.
public protocol AlarmScheduler: Sendable {
    /// 기존 알람을 전부 취소하고 새로 등록한다 (단일 알람 정책).
    func replaceAlarm(id: String, fireDate: Date, title: String) async throws
    func cancelAlarm() async
}
