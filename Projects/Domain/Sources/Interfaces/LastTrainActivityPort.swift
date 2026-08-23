import Foundation

/// Live Activity 포트 — 어댑터 구현(ActivityKit)은 App에 둔다.
/// 수명 정책: 알람 등록 성공 → start, 알람 취소 → end. LA는 알람 세션과 수명을 같이한다.
/// 어떤 메서드도 throws가 아니다 — LA 실패가 알람 등록·취소를 실패시키면 안 된다(어댑터가 흡수).
public protocol LastTrainActivityPort: Sendable {
    /// 알람 등록 성공 직후 호출 — 세션 정보와 경로로 LA를 시작한다. 이미 떠 있으면 어댑터가 교체한다.
    func start(session: AlarmInfo, route: LastRoute) async
    /// 상태 갱신. alert=true면 잠금화면에서 사용자 주의를 끄는 갱신(AlertConfiguration)으로 전달한다.
    func update(state: LastTrainActivityState, alert: Bool) async
    /// 세션 종료 — 마지막 상태를 남기고 LA를 닫는다.
    func end(final: LastTrainActivityState) async
    /// 사용자가 잠금화면에서 LA를 직접 지웠는지 — 지운 세션에는 다시 띄우지 않는다(재등록 전까지).
    var isDismissedByUser: Bool { get async }
}
