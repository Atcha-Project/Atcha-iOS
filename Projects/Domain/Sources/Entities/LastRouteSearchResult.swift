public enum LastRouteSearchResult: Sendable, Equatable {
    /// 첫 항목 = 가장 늦은 차
    case available([LastRoute])
    /// 오늘 막차 종료
    case serviceEnded
    /// 경로 없음 (도보권 등) — 서버 `TRS_011`("출발지와 도착지 간 거리가 너무 가깝습니다").
    case noRoute
    /// 서비스 지역(서울·경기·인천) 밖 — 서버 `TRS_012`. `noRoute`와 회복 경로가 다르다:
    /// 다른 경로를 찾아 줄 수 없고, 사용자가 목적지 자체를 바꿔야 한다.
    case outOfServiceRegion
}
