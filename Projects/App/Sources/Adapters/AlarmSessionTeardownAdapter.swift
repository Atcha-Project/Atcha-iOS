import Domain
import Foundation
import os

/// 계정 세션 종료 시 알람 세션 정리 — 조합 루트가 공유 인스턴스(스케줄러·LA·스냅샷·동기화)를
/// 그대로 넘긴다. 등록/취소 UseCase와 다른 인스턴스를 보면 정리가 헛돈다.
struct AlarmSessionTeardownAdapter: AlarmSessionTeardown {
    let alarmRepository: any AlarmRepository
    let scheduler: any AlarmScheduler
    let activityPort: any LastTrainActivityPort
    let snapshotStore: any AlarmSessionSnapshotStore
    let syncService: AlarmSyncService
    private static let logger = Logger(subsystem: "com.atcha.iOS.v2", category: "AlarmTeardown")

    func tearDown(cancelOnServer: Bool) async {
        if cancelOnServer, let routeId = await activeRouteId() {
            // 베스트 에포트 — 오프라인이어도 로그아웃을 막지 않는다. 서버에 남은 세션은
            // 다음 로그인의 refresh가 정본으로 되돌려 준다(같은 계정일 때만 의미가 있다).
            do {
                try await alarmRepository.cancel(lastRouteId: routeId)
            } catch {
                Self.logger.error("로그아웃 서버 알람 취소 실패(무시): \(error.localizedDescription, privacy: .public)")
            }
        }
        // 더는 울리면 안 되는 것이 핵심 — 표출 정리(LA)보다 알람 취소를 먼저 한다.
        await scheduler.cancelAlarm()
        await snapshotStore.clear()
        let now = Date()
        await activityPort.end(final: LastTrainActivityState(
            departureTime: now,
            alarmTime: now,
            urgency: .relaxed,
            changeBadgeExpiry: nil,
            phase: .active
        ))
        await syncService.resetForSignOut()
    }

    /// 만료 톰스톤은 이미 죽은 세션이라 서버 취소 대상이 아니다.
    private func activeRouteId() async -> String? {
        if let snapshot = await snapshotStore.load(), !snapshot.expired {
            return snapshot.info.lastRouteId
        }
        return await syncService.currentSession?.lastRouteId
    }
}
