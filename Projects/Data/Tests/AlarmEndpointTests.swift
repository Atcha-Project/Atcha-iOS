@testable import AtchaData
import CoreNetwork
import Foundation
import Testing

struct AlarmEndpointTests {
    @Test
    func register_postsJSONBodyWithLastRouteId() throws {
        let endpoint = AlarmEndpoint.register(AlarmRegisterRequestDTO(lastRouteId: "route-1"))
        #expect(endpoint.path == "/routes/user-routes")
        #expect(endpoint.method == .post)
        #expect(endpoint.headers == ["Content-Type": "application/json"])
        #expect(endpoint.queryItems.isEmpty)
        let body = try #require(endpoint.body)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(json == ["lastRouteId": "route-1"])
    }

    @Test
    func cancel_usesQueryNotBodyLikeLegacy() {
        let endpoint = AlarmEndpoint.cancel(lastRouteId: "route-1")
        #expect(endpoint.path == "/routes/user-routes")
        #expect(endpoint.method == .delete)
        #expect(endpoint.queryItems == [URLQueryItem(name: "lastRouteId", value: "route-1")])
        #expect(endpoint.body == nil)
    }

    @Test
    func refresh_getsRefreshPath() {
        let endpoint = AlarmEndpoint.refresh
        #expect(endpoint.path == "/routes/user-routes/refresh")
        #expect(endpoint.method == .get)
        #expect(endpoint.queryItems.isEmpty)
        #expect(endpoint.body == nil)
    }
}
