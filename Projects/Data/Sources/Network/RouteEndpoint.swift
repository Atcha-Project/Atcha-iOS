import CoreNetwork
import Domain
import Foundation

enum RouteEndpoint: Endpoint {
    case search(start: Coordinate, end: Coordinate)
    case detail(routeId: String)

    var path: String {
        switch self {
        case .search: "/routes/last-routes"
        case let .detail(routeId): "/routes/last-routes/\(routeId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .search, .detail: .get
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .search(start, end):
            [
                URLQueryItem(name: "startLat", value: String(start.latitude)),
                URLQueryItem(name: "startLon", value: String(start.longitude)),
                URLQueryItem(name: "endLat", value: String(end.latitude)),
                URLQueryItem(name: "endLon", value: String(end.longitude)),
            ]
        case .detail: []
        }
    }
}
