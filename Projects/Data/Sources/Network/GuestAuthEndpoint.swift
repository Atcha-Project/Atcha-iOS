import CoreNetwork
import Foundation

/// `POST /auth/guest` — 게스트 계정 생성/복구. 토큰이 필요 없는 유일한 인증 진입점이다.
/// base URL이 `/api`를 이미 포함하므로 여기 path에는 접두어를 쓰지 않는다(AppEnvironment 참조).
struct GuestAuthEndpoint: Endpoint {
    let request: GuestAuthRequestDTO

    var path: String { "/auth/guest" }
    var method: HTTPMethod { .post }
    var headers: [String: String] { ["Content-Type": "application/json"] }
    var body: Data? { try? JSONEncoder().encode(request) }
}
