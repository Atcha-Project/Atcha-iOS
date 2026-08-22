import Foundation

/// 디바이스 알람 포트 — 어댑터 구현(CoreAlarm ↔ AlarmKit)은 App에 둔다.
public protocol AlarmScheduler: Sendable {
    /// 권한이 미결정이면 시스템 다이얼로그를 띄운다. 거부 상태면 false.
    func requestAuthorization() async -> Bool
    /// 기존 알람을 전부 취소하고 새로 등록한다 (단일 알람 정책).
    func replaceAlarm(id: String, fireDate: Date, title: String) async throws
    func cancelAlarm() async
    /// 현재 스케줄된 로컬 알람의 발화 시각 — 없으면 nil (refresh의 변경 비교용).
    func scheduledFireDate() async -> Date?
}

/// 로컬 알람 제목 — 등록·재스케줄 경로가 같은 문구를 쓴다.
enum AlarmSchedulingDefaults {
    static let title = "막차 출발 알림"
}
