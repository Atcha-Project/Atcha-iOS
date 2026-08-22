import CoreAlarm
import Domain
import Foundation

/// CoreAlarm(AlarmKit 래퍼) → Domain `AlarmScheduler` 어댑터. CoreAlarm을 보는 곳은 App뿐.
final class CoreAlarmSchedulerAdapter: AlarmScheduler {
    private let scheduling: any AlarmKitScheduling

    init(scheduling: any AlarmKitScheduling = AlarmKitScheduler()) {
        self.scheduling = scheduling
    }

    func requestAuthorization() async -> Bool {
        await scheduling.requestAuthorization()
    }

    func replaceAlarm(id: String, fireDate: Date, title: String) async throws {
        try await scheduling.replaceAlarm(AlarmSpec(id: id, fireDate: fireDate, title: title))
    }

    func cancelAlarm() async {
        await scheduling.cancelAll()
    }

    func scheduledFireDate() async -> Date? {
        await scheduling.scheduledAlarm()?.fireDate
    }
}
