public enum LastRouteSearchResult: Sendable, Equatable {
    /// 첫 항목 = 가장 늦은 차
    case available([LastRoute])
    /// 오늘 막차 종료
    case serviceEnded
    /// 경로 없음 (도보권 등)
    case noRoute
}
