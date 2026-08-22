/// 로컬 노티 포트 — 구현은 App 어댑터(UNUserNotificationCenter는 App 한정 규칙).
/// 권한 요청은 명시된 한 시점(알람 등록 성공 직후)에서만 호출된다.
/// 거부 상태 기록·재요청 금지는 구현(어댑터) 책임. 실패는 밖으로 던지지 않는다.
public protocol LocalNotificationPort: Sendable {
    func requestAuthorizationIfNeeded() async
    /// LA dismiss 폴백용 즉시 발송. 권한 없으면 조용히 no-op.
    func post(title: String, body: String) async
}
