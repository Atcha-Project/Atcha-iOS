@testable import CoreNetwork
import Foundation
import Testing

private struct PingEndpoint: Endpoint {
    let path = "/ping"
    let method: HTTPMethod = .get
    var queryItems: [URLQueryItem] { [URLQueryItem(name: "q", value: "1")] }
}

struct URLSessionNetworkClientTests {
    @Test
    func urlRequest_composesPathMethodAndQuery() throws {
        let client = URLSessionNetworkClient(baseURL: URL(string: "https://api.example.com")!)
        let request = try client.urlRequest(for: PingEndpoint())
        #expect(request.url?.absoluteString == "https://api.example.com/ping?q=1")
        #expect(request.httpMethod == "GET")
    }
}
