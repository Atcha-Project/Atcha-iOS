import CoreNetwork
import Foundation

enum HomeEndpoint: Endpoint {
    case summary(HomeSummaryRequestDTO)

    var path: String {
        switch self {
        case .summary: "/v2/home/summary"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .summary: .get
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .summary(request):
            [URLQueryItem(name: "user_id", value: request.userID)]
        }
    }
}
