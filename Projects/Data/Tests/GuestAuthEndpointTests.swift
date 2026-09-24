@testable import AtchaData
import CoreNetwork
import Foundation
import Testing

struct GuestAuthEndpointTests {
    /// 서버 계약 핀: 토큰 없이 deviceId를 JSON body로 보내는 유일한 인증 진입점.
    /// path에 `/api` 접두어가 없는 것이 정상이다 — base URL이 이미 포함한다(AppEnvironment).
    @Test
    func guest_sendsDeviceIDAsJSONBodyWithoutAuthorization() throws {
        let endpoint = GuestAuthEndpoint(
            request: GuestAuthRequestDTO(deviceId: "DEVICE-1", fcmToken: "FCM")
        )

        #expect(endpoint.path == "/auth/guest")
        #expect(endpoint.method == .post)
        #expect(endpoint.headers == ["Content-Type": "application/json"])
        #expect(endpoint.queryItems.isEmpty)

        let body = try #require(endpoint.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["deviceId"] as? String == "DEVICE-1")
        #expect(json["fcmToken"] as? String == "FCM")
    }

    /// FCM 토큰 부재는 정상 상태(알림 권한 전) — 소셜 로그인과 달리 빈 문자열로
    /// 강등하지 않고 키를 생략한다.
    @Test
    func guest_withoutFcmToken_omitsKey() throws {
        let endpoint = GuestAuthEndpoint(
            request: GuestAuthRequestDTO(deviceId: "DEVICE-1", fcmToken: nil)
        )

        let body = try #require(endpoint.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["deviceId"] as? String == "DEVICE-1")
        #expect(json["fcmToken"] == nil)
    }
}
