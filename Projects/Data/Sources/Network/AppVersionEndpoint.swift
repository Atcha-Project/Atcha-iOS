import CoreNetwork
import Foundation

/// GET /app/version — 레거시 실측: 플랫폼 헤더 필수, 무토큰(로그인 전 스플래시에서 호출).
struct AppVersionEndpoint: Endpoint {
    var path: String { "/app/version" }
    var method: HTTPMethod { .get }
    var headers: [String: String] { ["X-Platform": "iOS"] }
}
