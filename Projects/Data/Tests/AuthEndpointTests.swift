@testable import AtchaData
import CoreNetwork
import Foundation
import Testing

struct AuthEndpointTests {
    /// 제안 계약 핀 — 서버 합의로 바뀌면 이 테스트가 먼저 깨져야 한다.
    @Test
    func guest_postsDeviceIdAndFcmTokenWithoutAuthorization() throws {
        let endpoint = AuthEndpoint.guest(GuestSessionRequestDTO(deviceId: "DEVICE", fcmToken: "FCM"))

        #expect(endpoint.path == "/auth/guest")
        #expect(endpoint.method == .post)
        #expect(endpoint.headers == ["Content-Type": "application/json"])
        let body = try #require(endpoint.body)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["deviceId"] as? String == "DEVICE")
        #expect(json["fcmToken"] as? String == "FCM")
    }
}
