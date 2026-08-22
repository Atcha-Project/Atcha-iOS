/// 알람 등록 플로우의 도메인 에러.
public enum AlarmError: Error, Equatable, Sendable {
    /// AlarmKit 권한 거부 — 서버 등록을 보류하고 설정 이동을 안내한다.
    case permissionDenied
}
