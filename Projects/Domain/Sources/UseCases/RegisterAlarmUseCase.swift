public protocol RegisterAlarmUseCase: Sendable {
    func execute(route: LastRoute) async throws
}

public struct DefaultRegisterAlarmUseCase: RegisterAlarmUseCase {
    private let repository: any AlarmRepository
    private let scheduler: any AlarmScheduler
    /// Live Activity 포트 — nil이면 LA 없이 동작한다(Example·기존 콜사이트 호환).
    private let activityPort: (any LastTrainActivityPort)?
    /// 로컬 노티 포트 — nil이면 알림 권한 요청 없이 동작한다(Example·기존 콜사이트 호환).
    private let notificationPort: (any LocalNotificationPort)?

    public init(
        repository: any AlarmRepository,
        scheduler: any AlarmScheduler,
        activityPort: (any LastTrainActivityPort)? = nil,
        notificationPort: (any LocalNotificationPort)? = nil
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.activityPort = activityPort
        self.notificationPort = notificationPort
    }

    public func execute(route: LastRoute) async throws {
        // 권한 요청이 최초 진입점 — 거부면 서버 등록까지 전부 보류한다.
        guard await scheduler.requestAuthorization() else {
            throw AlarmError.permissionDenied
        }
        // TODO: [미확정 #4] 단일 알람 규약(서버 교체 여부) 확정 전까지 클라이언트가 삭제 후 등록한다.
        //       기존 알람 확인 실패(= 등록된 알람 없음)와 삭제 실패는 등록을 막지 않는다.
        if let existing = try? await repository.refresh() {
            try? await repository.cancel(lastRouteId: existing.lastRouteId)
        }
        try await repository.register(lastRouteId: route.id)
        // 단일 알람 정책: 서버 등록이 성공한 뒤에만 로컬 알람을 교체한다.
        // TODO: [미확정] 서버 계산 알람 시각 스펙 확정 전까지 막차 출발 시각 − 버퍼로 스케줄한다.
        try await scheduler.replaceAlarm(
            id: route.id,
            fireDate: AlarmTiming.alarmFireDate(departureTime: route.departureTime),
            title: AlarmSchedulingDefaults.title
        )
        // 수명 정책: 알람 등록(서버+로컬)이 전부 성공한 뒤에만 LA를 시작한다.
        // start는 throws가 아니므로 LA 실패가 알람 등록을 실패시킬 수 없다.
        if let activityPort {
            let session = AlarmInfo(
                lastRouteId: route.id,
                departureTime: route.departureTime,
                updatedAt: nil, // 등록 직후라 서버 재계산 값이 아직 없다 — refresh가 갱신한다.
                isReal: true
            )
            await activityPort.start(session: session, route: route)
        }
        // 알림 권한 요청 — [미확정 #8 임시] 알람 등록 성공 직후가 유일한 요청 시점.
        // 순서 근거: AlarmKit 권한 팝업(흐름 시작, requestAuthorization)과 알림 권한 팝업(여기, 흐름 끝)
        // 사이에 서버 등록·로컬 스케줄·LA 시작이 끼어 있어 연속 팝업이 완화된다.
        // 등록 실패·권한 거부 경로에서는 위에서 throw로 빠져나가므로 여기까지 오지 않는다.
        // 거부 기록·재요청 스팸 방지는 어댑터 책임이고, 실패는 던지지 않는다(등록 결과에 영향 없음).
        await notificationPort?.requestAuthorizationIfNeeded()
    }
}
