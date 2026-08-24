/// 알림 권한 요청의 결과 — "이번 호출로 무엇이 일어났는가"를 담는다 (Phase 15).
/// 홈이 1회 안내 토스트를 띄울 유일한 트리거는 `deniedNow`다 — 요청 이력이 있으면
/// 시스템 요청도 안내도 다시 일어나지 않는다(재요청·재안내 스팸 금지).
public enum LocalNotificationAuthorizationOutcome: Sendable, Equatable {
    /// 이번 호출로 요청이 이뤄졌고 허용됨.
    case granted
    /// 이번 호출로 최초 요청이 이뤄졌고 거부됨 — 1회 안내의 유일한 트리거.
    case deniedNow
    /// 요청 이력 있음(결과 무관) 또는 요청 불가 — 요청도 안내도 없다.
    case alreadySettled
}

/// 로컬 노티 포트 — 구현은 App 어댑터(UNUserNotificationCenter는 App 한정 규칙).
/// 권한 요청은 명시된 한 시점(알람 등록 성공 직후)에서만 호출된다.
/// 거부 상태 기록·재요청 금지는 구현(어댑터) 책임. 실패는 밖으로 던지지 않는다.
public protocol LocalNotificationPort: Sendable {
    @discardableResult
    func requestAuthorizationIfNeeded() async -> LocalNotificationAuthorizationOutcome
    /// LA alert 도달 불가 폴백용 즉시 발송. 권한 없으면 조용히 no-op.
    func post(title: String, body: String) async
}
