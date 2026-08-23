/// 알람 등록 플로우의 도메인 에러.
public enum AlarmError: Error, Equatable, Sendable {
    /// AlarmKit 권한 거부 — 서버 등록을 보류하고 설정 이동을 안내한다.
    case permissionDenied
    /// 알람 발화 시각(출발 − 도보 − 버퍼)이 이미 과거 — 서버 등록 성공 후 로컬 스케줄이
    /// 실패하는 서버/로컬 불일치를 사전 차단한다(등록 자체를 시작하지 않는다).
    case tooLate
}
