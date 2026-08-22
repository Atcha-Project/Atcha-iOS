import CoreNetwork
import Domain
import Foundation

enum PlaceEndpoint: Endpoint {
    case search(keyword: String, near: Coordinate?)
    case reverseGeocode(Coordinate)

    var path: String {
        switch self {
        case .search: "/locations"
        case .reverseGeocode: "/locations/rgeo"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .search, .reverseGeocode: .get
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .search(keyword, near):
            // 좌표 미지정 시 0.0 전송은 레거시 실측 규약.
            [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "lat", value: String(near?.latitude ?? 0.0)),
                URLQueryItem(name: "lon", value: String(near?.longitude ?? 0.0)),
            ]
        case let .reverseGeocode(coordinate):
            [
                URLQueryItem(name: "lat", value: String(coordinate.latitude)),
                URLQueryItem(name: "lon", value: String(coordinate.longitude)),
            ]
        }
    }
}
