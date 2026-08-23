import Foundation

public protocol CancelAlarmUseCase: Sendable {
    func execute(lastRouteId: String) async throws
}

public struct DefaultCancelAlarmUseCase: CancelAlarmUseCase {
    private let repository: any AlarmRepository
    private let scheduler: any AlarmScheduler
    /// Live Activity 포트 — nil이면 LA 없이 동작한다(Example·기존 콜사이트 호환).
    private let activityPort: (any LastTrainActivityPort)?
    /// 세션 스냅샷(Phase 14) — 취소는 clear 시점이다. nil이면 영속화 없이 동작한다.
    private let snapshotStore: (any AlarmSessionSnapshotStore)?

    public init(
        repository: any AlarmRepository,
        scheduler: any AlarmScheduler,
        activityPort: (any LastTrainActivityPort)? = nil,
        snapshotStore: (any AlarmSessionSnapshotStore)? = nil
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.activityPort = activityPort
        self.snapshotStore = snapshotStore
    }

    public func execute(lastRouteId: String) async throws {
        try await repository.cancel(lastRouteId: lastRouteId)
        await scheduler.cancelAlarm()
        // 세션이 유저 의사로 끝났다 — 재실행 브리지(스냅샷)도 함께 지운다.
        await snapshotStore?.clear()
        // 수명 정책: 알람 세션이 끝나면 LA도 끝낸다. 유저 취소는 실패 상태가 아니므로
        // phase는 .active로 종료한다. end는 즉시 닫는 경로라 시각 값은 표시에 쓰이지 않는다.
        if let activityPort {
            let now = Date()
            await activityPort.end(
                final: LastTrainActivityState(
                    departureTime: now,
                    alarmTime: now,
                    urgency: .relaxed,
                    changeBadgeExpiry: nil,
                    phase: .active
                )
            )
        }
    }
}
