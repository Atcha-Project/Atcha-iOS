import CoreNetwork
import Domain
import Foundation

/// `/auth/check`·`/auth/login` — 소셜 자격 증명을 Bearer로 보내는 특수 계약(레거시 실측).
/// AuthenticatedNetworkClient를 타면 Authorization이 서버 토큰으로 덮이므로,
/// 이 엔드포인트는 반드시 plain client로 호출한다(AuthRepositoryImpl 주입 규약).
enum AuthEndpoint: Endpoint {
    case check(SocialCredential)
    case login(SocialCredential, fcmToken: String?)
    case signUp(SocialCredential, SignUpRequestDTO)

    var path: String {
        switch self {
        case .check: "/auth/check"
        case .login: "/auth/login"
        case .signUp: "/auth/sign-up"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .check, .login: .get
        case .signUp: .post
        }
    }

    var headers: [String: String] {
        switch self {
        case let .check(credential), let .login(credential, _):
            ["Authorization": "Bearer \(credential.accessToken)"]
        case let .signUp(credential, _):
            [
                "Authorization": "Bearer \(credential.accessToken)",
                "Content-Type": "application/json",
            ]
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .check(credential):
            [URLQueryItem(name: "provider", value: String(credential.provider.serverCode))]
        case let .login(credential, fcmToken):
            [
                URLQueryItem(name: "provider", value: String(credential.provider.serverCode)),
                // 레거시 실측: FCM 토큰 부재 시 빈 문자열 전송.
                URLQueryItem(name: "fcmToken", value: fcmToken ?? ""),
            ]
        case .signUp: []
        }
    }

    var body: Data? {
        switch self {
        case .check, .login: nil
        case let .signUp(_, request): try? JSONEncoder().encode(request)
        }
    }
}

extension SocialLoginProvider {
    /// 서버 provider 코드 — 레거시 `LoginType` raw value 실측(kakao=0, apple=1).
    var serverCode: Int {
        switch self {
        case .kakao: 0
        case .apple: 1
        }
    }
}
