import AppIntents
import Foundation

/// AlarmKit 위에서 단일 알람 교체 정책을 구현하는 기본 스케줄러.
///
/// AlarmKit의 `Alarm`은 제목을 되돌려주지 않으므로, 마지막으로 등록한 스펙을
/// 로컬 레코드로 보관했다가 `scheduledAlarm()`에서 시스템 알람 존재 여부와
/// 대조해 복원한다 (발화·삭제로 사라진 알람은 레코드도 함께 정리).
public actor AlarmKitScheduler: AlarmKitScheduling {
    private let engine: any AlarmEngine
    private let recordStore: any AlarmRecordStoring
    /// stop 버튼("확인") 탭 시 앱 프로세스에서 실행할 인텐트 (Phase 13 발화 감지).
    /// 인텐트 **타입**은 App이 소유하고 여기엔 인스턴스만 주입된다(App → CoreAlarm 한 방향) —
    /// AppIntents는 시스템 프레임워크라 무의존 원칙 위배가 아니다.
    private let stopIntent: (any LiveActivityIntent)?

    public init(stopIntent: (any LiveActivityIntent)? = nil) {
        self.init(
            engine: AlarmKitEngine(),
            recordStore: UserDefaultsAlarmRecordStore(),
            stopIntent: stopIntent
        )
    }

    init(
        engine: any AlarmEngine,
        recordStore: any AlarmRecordStoring,
        stopIntent: (any LiveActivityIntent)? = nil
    ) {
        self.engine = engine
        self.recordStore = recordStore
        self.stopIntent = stopIntent
    }

    public func requestAuthorization() async -> Bool {
        (try? await engine.requestAuthorization()) ?? false
    }

    public func replaceAlarm(_ spec: AlarmSpec) async throws {
        await cancelEngineAlarms()
        recordStore.clear()
        let uuid = UUID()
        do {
            try await engine.schedule(
                id: uuid, fireDate: spec.fireDate, title: spec.title, stopIntent: stopIntent
            )
        } catch where stopIntent != nil {
            // 회귀 금지: 인텐트 주입이 알람 등록을 실패시키면 안 된다 —
            // 인텐트 없이 재시도한다(발화 감지만 포기, 알람은 그대로 성립).
            try await engine.schedule(
                id: uuid, fireDate: spec.fireDate, title: spec.title, stopIntent: nil
            )
        }
        recordStore.save(ScheduledAlarmRecord(uuid: uuid, spec: spec))
    }

    public func cancelAll() async {
        await cancelEngineAlarms()
        recordStore.clear()
    }

    public func scheduledAlarm() async -> AlarmSpec? {
        guard let record = recordStore.load() else { return nil }
        guard await engine.alarmIDs().contains(record.uuid) else {
            recordStore.clear()
            return nil
        }
        return record.spec
    }

    private func cancelEngineAlarms() async {
        for id in await engine.alarmIDs() {
            await engine.cancel(id: id)
        }
    }
}

/// AlarmKit 호출 시임 — 테스트는 스텁 엔진으로 대체한다 (AlarmKit 직접 호출 금지 규약).
protocol AlarmEngine: Sendable {
    func requestAuthorization() async throws -> Bool
    func schedule(
        id: UUID, fireDate: Date, title: String, stopIntent: (any LiveActivityIntent)?
    ) async throws
    func cancel(id: UUID) async
    func alarmIDs() async -> [UUID]
}
