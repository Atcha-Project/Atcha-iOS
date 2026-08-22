/// AlarmKit 래퍼의 공개 계약. 구현은 `AlarmKitScheduler`, 소비자는 App의 어댑터뿐.
public protocol AlarmKitScheduling: Sendable {
    /// 권한이 미결정이면 시스템 다이얼로그를 띄운다. 거부 상태면 false.
    func requestAuthorization() async -> Bool
    /// 전부 취소 후 등록 (단일 알람 정책).
    func replaceAlarm(_ spec: AlarmSpec) async throws
    func cancelAll() async
    func scheduledAlarm() async -> AlarmSpec?
}
