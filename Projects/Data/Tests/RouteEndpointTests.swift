@testable import AtchaData
import CoreNetwork
import Domain
import Foundation
import Testing

struct RouteEndpointTests {
    @Test
    func search_composesPathMethodAndLegacyQueryNames() {
        let endpoint = RouteEndpoint.search(
            start: Coordinate(latitude: 37.49794, longitude: 127.02761),
            end: Coordinate(latitude: 37.554722, longitude: 126.970833)
        )
        #expect(endpoint.path == "/routes/last-routes")
        #expect(endpoint.method == .get)
        #expect(endpoint.queryItems == [
            URLQueryItem(name: "startLat", value: "37.49794"),
            URLQueryItem(name: "startLon", value: "127.02761"),
            URLQueryItem(name: "endLat", value: "37.554722"),
            URLQueryItem(name: "endLon", value: "126.970833"),
        ])
        #expect(endpoint.body == nil)
    }

    @Test
    func detail_interpolatesRouteIdIntoPath() {
        let endpoint = RouteEndpoint.detail(routeId: "route-1")
        #expect(endpoint.path == "/routes/last-routes/route-1")
        #expect(endpoint.method == .get)
        #expect(endpoint.queryItems.isEmpty)
    }
}
