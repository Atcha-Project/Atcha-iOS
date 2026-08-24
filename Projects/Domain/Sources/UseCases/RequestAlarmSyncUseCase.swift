import Foundation

/// 홈 pull-to-refresh의 수동 갱신 진입점(Phase 16) — Observe 계열과 같은 패턴으로
/// App의 AlarmSyncService(AlarmSyncRequesting)를 감싼다. 완료 = 동기화 종료(성공/실패
/// 불문)이고, 갱신된 값은 ObserveAlarmUseCase 스트림이 따로 나른다.
public protocol RequestAlarmSyncUseCase: Sendable {
    func execute() async
}

public struct DefaultRequestAlarmSyncUseCase: RequestAlarmSyncUseCase {
    private let requesting: any AlarmSyncRequesting

    public init(requesting: any AlarmSyncRequesting) {
        self.requesting = requesting
    }

    public func execute() async {
        await requesting.syncNow()
    }
}
