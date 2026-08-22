/// 위치 조회 실패 사유 — 권한 거부를 구분해야 Feature가 "검색 유도 + 설정 이동" UX로 분기할 수 있다.
public enum LocationError: Error, Equatable, Sendable {
    case permissionDenied
    case unavailable
}
