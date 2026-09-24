public struct Coordinate: Equatable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// 서비스 지역(서울·경기·인천)의 중심으로 쓰는 좌표 — 서울시청.
    ///
    /// **위치를 모를 때 쓰는 폴백이다.** 장소 검색 API가 `lat`/`lon`을 필수로 받는데
    /// (생략하면 `REQ_005`), 좌표는 결과 집합이 아니라 **거리 표기·정렬**에만 쓰인다
    /// (실측 2026-09-25: 부산 좌표로 '강남역'을 검색해도 같은 20건이 나오고 `radius`만
    /// 316km로 바뀐다). 그래서 이 폴백은 결과를 잃지 않는다.
    ///
    /// 0,0을 보내면 안 된다 — 유효한 좌표로 취급되어 **결과가 0건이 된다**(같은 실측).
    public static let serviceRegionCenter = Coordinate(latitude: 37.5665, longitude: 126.9780)
}
