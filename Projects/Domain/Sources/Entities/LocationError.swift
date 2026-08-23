/// 위치 조회 실패 사유 — 사유별로 회복 경로가 다르므로 Feature가 안내를 분기한다(Phase 17).
public enum LocationError: Error, Equatable, Sendable {
    /// 이 앱의 권한 거부 — "설정으로 이동"이 유효한 회복 경로다.
    case permissionDenied
    /// 스크린타임·MDM 제약 — 사용자가 설정으로 못 푼다. "설정으로 이동" 안내 금지.
    case restricted
    /// 기기 전역 위치 서비스 OFF — 앱 권한이 아니라 시스템 설정의 문제.
    case servicesDisabled
    case unavailable
}
