@testable import AtchaData
import CoreNetwork
import Foundation
import Testing

struct UserEndpointTests {
    /// 레거시 실측 계약 핀: 조회에만 플랫폼 식별 헤더가 붙는다.
    @Test
    func me_sendsPlatformHeader() {
        let endpoint = UserEndpoint.me

        #expect(endpoint.path == "/members/me")
        #expect(endpoint.method == .get)
        #expect(endpoint.headers == ["X-Platform": "iOS"])
        #expect(endpoint.body == nil)
    }

    @Test
    func updateHomeAddress_patchesWithJSONBody() throws {
        let endpoint = UserEndpoint.updateHomeAddress(
            HomePatchRequestDTO(address: "서울 어딘가 1-2", lat: 37.5, lon: 127.0)
        )

        #expect(endpoint.path == "/members/me/home-address")
        #expect(endpoint.method == .patch)
        #expect(endpoint.headers == ["Content-Type": "application/json"])

        let json = try decodeBody(endpoint)
        #expect(json["address"] as? String == "서울 어딘가 1-2")
        #expect(json["lat"] as? Double == 37.5)
        #expect(json["lon"] as? Double == 127.0)
    }

    @Test
    func updateAlertFrequencies_patchesWithJSONBody() throws {
        let endpoint = UserEndpoint.updateAlertFrequencies(
            AlertFrequencyPatchRequestDTO(alertFrequencies: [1, 10])
        )

        #expect(endpoint.path == "/members/me/alert-frequency")
        #expect(endpoint.method == .patch)

        let json = try decodeBody(endpoint)
        #expect(json["alertFrequencies"] as? [Int] == [1, 10])
    }

    private func decodeBody(_ endpoint: any Endpoint) throws -> [String: Any] {
        let body = try #require(endpoint.body)
        return try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
    }
}
