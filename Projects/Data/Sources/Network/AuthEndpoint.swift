import CoreNetwork
import Foundation

/// 게스트 토큰 발급 — 토큰 없이 호출한다. AuthenticatedNetworkClient를 타면 401 복구가
/// 발급 경로로 재귀할 수 있으므로 반드시 plain client로 호출한다(AuthRepositoryImpl 주입 규약).
enum AuthEndpoint: Endpoint {
    // TODO: [서버 합의] 경로·필드는 클라 제안안(POST /auth/guest). 확정되면 이 enum만 고친다.
    case guest(GuestSessionRequestDTO)

    var path: String {
        switch self {
        case .guest: "/auth/guest"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .guest: .post
        }
    }

    var headers: [String: String] {
        switch self {
        case .guest: ["Content-Type": "application/json"]
        }
    }

    var body: Data? {
        switch self {
        case let .guest(request): try? JSONEncoder().encode(request)
        }
    }
}
