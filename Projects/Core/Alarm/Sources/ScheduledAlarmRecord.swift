import Foundation

/// 마지막으로 등록한 알람의 로컬 레코드 — `scheduledAlarm()` 복원용.
struct ScheduledAlarmRecord: Codable, Equatable, Sendable {
    let uuid: UUID
    let id: String
    let fireDate: Date
    let title: String

    init(uuid: UUID, spec: AlarmSpec) {
        self.uuid = uuid
        self.id = spec.id
        self.fireDate = spec.fireDate
        self.title = spec.title
    }

    var spec: AlarmSpec {
        AlarmSpec(id: id, fireDate: fireDate, title: title)
    }
}

protocol AlarmRecordStoring: Sendable {
    func load() -> ScheduledAlarmRecord?
    func save(_ record: ScheduledAlarmRecord)
    func clear()
}

// UserDefaults는 문서화된 thread-safe지만 SDK가 Sendable로 표기하지 않아 @unchecked가 필요하다.
final class UserDefaultsAlarmRecordStore: AlarmRecordStoring, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "core.alarm.scheduled-record"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ScheduledAlarmRecord? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ScheduledAlarmRecord.self, from: data)
    }

    func save(_ record: ScheduledAlarmRecord) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
