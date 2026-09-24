@testable import AtchaData
import CoreNetwork
import Testing

struct AppVersionEndpointTests {
    @Test
    func appVersion_sendsPlatformHeader() {
        let endpoint = AppVersionEndpoint()
        #expect(endpoint.path == "/app/version")
        #expect(endpoint.method == .get)
        #expect(endpoint.headers == ["X-Platform": "iOS"])
    }
}
