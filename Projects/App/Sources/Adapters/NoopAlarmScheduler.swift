import Domain
import Foundation

/// Phase 6 임시 어댑터: 서버 알람 등록은 실동작, 로컬 스케줄은 no-op.
/// Phase 7에서 CoreAlarm(AlarmKit) 기반 어댑터로 교체된다.
struct NoopAlarmScheduler: AlarmScheduler {
    func replaceAlarm(id: String, fireDate: Date, title: String) async throws {}
    func cancelAlarm() async {}
}
