import CoreNetwork
import Foundation

enum UserEndpoint: Endpoint {
    case me
    case updateHomeAddress(HomePatchRequestDTO)
    case updateAlertFrequencies(AlertFrequencyPatchRequestDTO)

    var path: String {
        switch self {
        case .me: "/members/me"
        case .updateHomeAddress: "/members/me/home-address"
        case .updateAlertFrequencies: "/members/me/alert-frequency"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .me: .get
        case .updateHomeAddress, .updateAlertFrequencies: .patch
        }
    }

    var headers: [String: String] {
        switch self {
        // 레거시 실측: 조회에만 플랫폼 식별 헤더가 붙는다.
        case .me: ["X-Platform": "iOS"]
        case .updateHomeAddress, .updateAlertFrequencies:
            ["Content-Type": "application/json"]
        }
    }

    var body: Data? {
        switch self {
        case .me: nil
        case let .updateHomeAddress(request): try? JSONEncoder().encode(request)
        case let .updateAlertFrequencies(request): try? JSONEncoder().encode(request)
        }
    }
}
