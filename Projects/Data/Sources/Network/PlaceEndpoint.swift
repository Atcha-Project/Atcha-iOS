import CoreNetwork
import Domain
import Foundation

enum PlaceEndpoint: Endpoint {
    case search(keyword: String, near: Coordinate?)
    case reverseGeocode(Coordinate)
    case serviceRegion(Coordinate)

    var path: String {
        switch self {
        case .search: "/locations"
        case .reverseGeocode: "/locations/rgeo"
        case .serviceRegion: "/locations/is-service-region"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .search, .reverseGeocode, .serviceRegion: .get
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .search(keyword, near):
            // 서버는 lat/lon을 **필수**로 받고(생략하면 REQ_005), 좌표는 결과 집합이 아니라
            // 거리 표기·정렬에만 쓴다. 단 (0,0)은 유효한 좌표로 취급되어 **0건**이 온다 —
            // 레거시의 "미지정 시 0.0" 규약을 그대로 따르면 위치를 얻기 전의 모든 검색이
            // 통째로 빈다. 그래서 모를 때는 서비스 지역 중심을 보낸다(실측 근거는 Coordinate).
            let bias = near ?? .serviceRegionCenter
            return [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "lat", value: String(bias.latitude)),
                URLQueryItem(name: "lon", value: String(bias.longitude)),
            ]
        case let .reverseGeocode(coordinate), let .serviceRegion(coordinate):
            return [
                URLQueryItem(name: "lat", value: String(coordinate.latitude)),
                URLQueryItem(name: "lon", value: String(coordinate.longitude)),
            ]
        }
    }
}
