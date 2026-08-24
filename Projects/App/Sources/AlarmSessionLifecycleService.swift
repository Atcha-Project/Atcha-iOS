import Domain
import Foundation
import os

/// 알람 발화 이후의 세션 수명 로직 (Phase 13) — stopIntent("확인" 탭)가 조합 루트를
/// 거쳐 도달하는 유일한 지점. 시간 경과 판정(만료)은 AlarmSyncService의 wake 시점
/// 리컨실 몫이고, 여기는 "확인" 사건의 기록과 표출 전이만 담당한다.
@MainActor
final class AlarmSessionLifecycleService {
    /// departed 전환·예약 소멸 경로 — LA 어댑터가 구현한다(실패 전부 흡수, non-throwing).
    private let liveActivity: any LastTrainDepartureEnding
    /// 확인 기록 영속화 (Phase 14) — 강제 종료·재실행 후에도 남아 재시작 판정
    /// (확인된 세션 재시작 금지)의 재료가 된다.
    private let snapshotStore: any AlarmSessionSnapshotStore
    private static let logger = Logger(
        subsystem: "com.atcha.iOS.v2", category: "SessionLifecycle"
    )

    /// stopIntent 확인 기록 — 스냅샷 영속화의 인메모리 미러.
    private(set) var isAcknowledged = false

    init(
        liveActivity: any LastTrainDepartureEnding,
        snapshotStore: any AlarmSessionSnapshotStore
    ) {
        self.liveActivity = liveActivity
        self.snapshotStore = snapshotStore
    }

    /// 알람 "확인" 탭(stopIntent 실행) — ① 확인 기록(스냅샷 영속화) ② LA departed 전환
    /// ③ 출발+10분 자동 소멸 예약. ②③은 어댑터의 end 한 번으로 구현된다
    /// (final content = departed, dismissalPolicy = .after) — 앱이 다시 깨지
    /// 않아도 잠금화면에서 시스템이 내린다.
    func alarmAcknowledged() async {
        // 로그는 자동 검수 ②(강제 종료 후 인텐트 실행 여부 판정)의 증적 채널이다.
        Self.logger.info("알람 확인(stopIntent) 수신 — departed 전환 + 자동 소멸 예약")
        isAcknowledged = true
        // 세션 스냅샷이 있을 때만 기록한다 — 스냅샷 없는 확인(이론상 경합)은 남길 곳이 없고,
        // 그 경우의 정리는 wake 시점 리컨실이 맡는다.
        if let snapshot = await snapshotStore.load() {
            await snapshotStore.save(snapshot.updating(acknowledged: true))
        }
        await liveActivity.endAsDeparted()
    }
}
