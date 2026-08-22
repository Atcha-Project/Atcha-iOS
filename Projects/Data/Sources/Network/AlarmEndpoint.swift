import CoreNetwork
import Foundation

enum AlarmEndpoint: Endpoint {
    case register(AlarmRegisterRequestDTO)
    case cancel(lastRouteId: String)
    case refresh

    var path: String {
        switch self {
        case .register, .cancel: "/routes/user-routes"
        case .refresh: "/routes/user-routes/refresh"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .register: .post
        case .cancel: .delete
        case .refresh: .get
        }
    }

    var headers: [String: String] {
        switch self {
        case .register: ["Content-Type": "application/json"]
        case .cancel, .refresh: [:]
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        // 삭제는 body가 아니라 쿼리로 lastRouteId를 받는다 (레거시 실측).
        case let .cancel(lastRouteId):
            [URLQueryItem(name: "lastRouteId", value: lastRouteId)]
        case .register, .refresh: []
        }
    }

    var body: Data? {
        switch self {
        case let .register(request): try? JSONEncoder().encode(request)
        case .cancel, .refresh: nil
        }
    }
}
