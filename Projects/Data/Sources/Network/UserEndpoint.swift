import CoreNetwork
import Foundation

enum UserEndpoint: Endpoint {
    case me
    case updateHomeAddress(HomePatchRequestDTO)
    case updateAlertFrequencies(AlertFrequencyPatchRequestDTO)
    /// 서버 확정(2026-09 게스트 흐름): 알림 토큰 갱신은 내 정보 PUT으로 한다.
    case updateFcmToken(FcmTokenUpdateRequestDTO)

    var path: String {
        switch self {
        case .me, .updateFcmToken: "/members/me"
        case .updateHomeAddress: "/members/me/home-address"
        case .updateAlertFrequencies: "/members/me/alert-frequency"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .me: .get
        case .updateHomeAddress, .updateAlertFrequencies: .patch
        case .updateFcmToken: .put
        }
    }

    var headers: [String: String] {
        switch self {
        // 레거시 실측: 조회에만 플랫폼 식별 헤더가 붙는다.
        case .me: ["X-Platform": "iOS"]
        case .updateHomeAddress, .updateAlertFrequencies, .updateFcmToken:
            ["Content-Type": "application/json"]
        }
    }

    var body: Data? {
        switch self {
        case .me: nil
        case let .updateHomeAddress(request): try? JSONEncoder().encode(request)
        case let .updateAlertFrequencies(request): try? JSONEncoder().encode(request)
        case let .updateFcmToken(request): try? JSONEncoder().encode(request)
        }
    }
}
