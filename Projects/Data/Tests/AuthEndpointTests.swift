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

    /// 레거시 실측 계약 핀: sign-up도 소셜 토큰이 Bearer로, 필드는 JSON body로.
    @Test
    func signUp_sendsSocialBearerAndJSONBody() throws {
        let request = SignUpRequestDTO(
            provider: 0,
            userName: "",
            address: "서울 어딘가 1-2",
            lat: 37.5,
            lon: 127.0,
            alertFrequencies: [1, 10],
            fcmToken: ""
        )
        let endpoint = AuthEndpoint.signUp(kakaoCredential, request)

        #expect(endpoint.path == "/auth/sign-up")
        #expect(endpoint.method == .post)
        #expect(endpoint.headers == [
            "Authorization": "Bearer KAKAO_AT",
            "Content-Type": "application/json",
        ])
        #expect(endpoint.queryItems.isEmpty)

        let body = try #require(endpoint.body)
        let json = try #require(
            try JSONSerialization.jsonObject(with: body) as? [String: Any]
        )
        #expect(json["provider"] as? Int == 0)
        #expect(json["userName"] as? String == "")
        #expect(json["address"] as? String == "서울 어딘가 1-2")
        #expect(json["lat"] as? Double == 37.5)
        #expect(json["lon"] as? Double == 127.0)
        #expect(json["alertFrequencies"] as? [Int] == [1, 10])
        #expect(json["fcmToken"] as? String == "")
    }
}
