public protocol RegisterAlarmUseCase: Sendable {
    func execute(route: LastRoute) async throws
}

public struct DefaultRegisterAlarmUseCase: RegisterAlarmUseCase {
    private let repository: any AlarmRepository
    private let scheduler: any AlarmScheduler

    public init(repository: any AlarmRepository, scheduler: any AlarmScheduler) {
        self.repository = repository
        self.scheduler = scheduler
    }

    public func execute(route: LastRoute) async throws {
        // TODO: [미확정 #4] 단일 알람 규약(서버 교체 여부) 확정 전까지 클라이언트가 삭제 후 등록한다.
        //       기존 알람 확인 실패(= 등록된 알람 없음)와 삭제 실패는 등록을 막지 않는다.
        if let existing = try? await repository.refresh() {
            try? await repository.cancel(lastRouteId: existing.lastRouteId)
        }
        try await repository.register(lastRouteId: route.id)
        // 단일 알람 정책: 서버 등록이 성공한 뒤에만 로컬 알람을 교체한다.
        // TODO: [미확정] 서버 계산 알람 시각 스펙 확정 전까지 막차 출발 시각으로 스케줄한다.
        try await scheduler.replaceAlarm(id: route.id, fireDate: route.departureTime, title: "막차 출발 알림")
    }
}
