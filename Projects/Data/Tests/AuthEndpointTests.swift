@testable import AtchaData
import CoreNetwork
import Domain
import Foundation
import Testing

struct AuthEndpointTests {
    private let kakaoCredential = SocialCredential(provider: .kakao, accessToken: "KAKAO_AT")
    private let appleCredential = SocialCredential(provider: .apple, accessToken: "APPLE_IDT")

    /// 레거시 실측 계약 핀: 소셜 토큰이 Bearer로, provider는 kakao=0.
    @Test
    func check_kakao_sendsSocialBearerAndProviderZero() {
        let endpoint = AuthEndpoint.check(kakaoCredential)

        #expect(endpoint.path == "/auth/check")
        #expect(endpoint.method == .get)
        #expect(endpoint.headers == ["Authorization": "Bearer KAKAO_AT"])
        #expect(endpoint.queryItems == [URLQueryItem(name: "provider", value: "0")])
    }

    @Test
    func check_apple_sendsProviderOne() {
        let endpoint = AuthEndpoint.check(appleCredential)

        #expect(endpoint.headers == ["Authorization": "Bearer APPLE_IDT"])
        #expect(endpoint.queryItems == [URLQueryItem(name: "provider", value: "1")])
    }

    @Test
    func login_sendsProviderAndFcmToken() {
        let endpoint = AuthEndpoint.login(kakaoCredential, fcmToken: "FCM")

        #expect(endpoint.path == "/auth/login")
        #expect(endpoint.method == .get)
        #expect(endpoint.headers == ["Authorization": "Bearer KAKAO_AT"])
        #expect(endpoint.queryItems == [
            URLQueryItem(name: "provider", value: "0"),
            URLQueryItem(name: "fcmToken", value: "FCM"),
        ])
    }

    /// 레거시 실측: FCM 토큰 부재 시 빈 문자열 전송.
    @Test
    func login_withoutFcmToken_sendsEmptyStringLikeLegacy() {
        let endpoint = AuthEndpoint.login(appleCredential, fcmToken: nil)

        #expect(endpoint.queryItems == [
            URLQueryItem(name: "provider", value: "1"),
            URLQueryItem(name: "fcmToken", value: ""),
        ])
    }
}
