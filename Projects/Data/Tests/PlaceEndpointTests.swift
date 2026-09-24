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

    /// **좌표를 모를 때 (0,0)을 보내면 안 된다.** 서버는 그걸 유효한 좌표로 취급해
    /// 결과를 0건으로 돌려준다(2026-09-25 실측) — 위치를 얻기 전의 모든 검색이 통째로
    /// 비는 원인이었다. lat/lon은 필수라 생략도 못 한다(REQ_005).
    @Test
    func search_withoutCoordinate_fallsBackToServiceRegionCenterNotZero() {
        let endpoint = PlaceEndpoint.search(keyword: "홍대입구", near: nil)

        #expect(endpoint.queryItems == [
            URLQueryItem(name: "keyword", value: "홍대입구"),
            URLQueryItem(name: "lat", value: String(Coordinate.serviceRegionCenter.latitude)),
            URLQueryItem(name: "lon", value: String(Coordinate.serviceRegionCenter.longitude)),
        ])
        #expect(endpoint.queryItems.first { $0.name == "lat" }?.value != "0.0")
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

    @Test
    func serviceRegion_composesQuery() {
        let endpoint = PlaceEndpoint.serviceRegion(Coordinate(latitude: 37.560908, longitude: 126.921537))
        #expect(endpoint.path == "/locations/is-service-region")
        #expect(endpoint.method == .get)
        #expect(endpoint.queryItems == [
            URLQueryItem(name: "lat", value: "37.560908"),
            URLQueryItem(name: "lon", value: "126.921537"),
        ])
    }
}
