@testable import AtchaData
import CoreNetwork
import Domain
import Foundation
import Testing

struct PlaceEndpointTests {
    @Test
    func search_sendsKeywordAndCoordinate() {
        let endpoint = PlaceEndpoint.search(
            keyword: "홍대입구",
            near: Coordinate(latitude: 37.556748, longitude: 126.923643)
        )
        #expect(endpoint.path == "/locations")
        #expect(endpoint.method == .get)
        #expect(endpoint.queryItems == [
            URLQueryItem(name: "keyword", value: "홍대입구"),
            URLQueryItem(name: "lat", value: "37.556748"),
            URLQueryItem(name: "lon", value: "126.923643"),
        ])
    }

    @Test
    func search_withoutCoordinate_sendsZeroesLikeLegacy() {
        let endpoint = PlaceEndpoint.search(keyword: "홍대입구", near: nil)
        #expect(endpoint.queryItems == [
            URLQueryItem(name: "keyword", value: "홍대입구"),
            URLQueryItem(name: "lat", value: "0.0"),
            URLQueryItem(name: "lon", value: "0.0"),
        ])
    }

    @Test
    func reverseGeocode_composesQuery() {
        let endpoint = PlaceEndpoint.reverseGeocode(Coordinate(latitude: 37.560908, longitude: 126.921537))
        #expect(endpoint.path == "/locations/rgeo")
        #expect(endpoint.method == .get)
        #expect(endpoint.queryItems == [
            URLQueryItem(name: "lat", value: "37.560908"),
            URLQueryItem(name: "lon", value: "126.921537"),
        ])
    }
}
