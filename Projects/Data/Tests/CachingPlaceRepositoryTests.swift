@testable import AtchaData
import CoreStorage
import Domain
import Foundation
import Synchronization
import Testing

private struct UpstreamError: Error {}

private final class InMemoryKeyValueStore: KeyValueStore {
    private let storage = Mutex<[String: Data]>([:])

    func data(forKey key: String) throws -> Data? { storage.withLock { $0[key] } }
    func set(_ data: Data, forKey key: String) throws { storage.withLock { $0[key] = data } }
    func removeValue(forKey key: String) throws { storage.withLock { $0[key] = nil } }
}

/// 상류 호출을 세는 스파이 — 캐시 적중의 관찰 가능한 정의가 "왕복이 안 일어남"이다.
private final class SpyPlaceRepository: PlaceRepository, @unchecked Sendable {
    private let geocodeCalls = Mutex(0)
    private let searchCalls = Mutex(0)
    private let serviceRegionCalls = Mutex(0)
    private let shouldFail = Mutex(false)
    private let emptyResult = Mutex(false)

    var geocodeCount: Int { geocodeCalls.withLock { $0 } }
    var searchCount: Int { searchCalls.withLock { $0 } }
    var serviceRegionCount: Int { serviceRegionCalls.withLock { $0 } }
    var fails: Bool {
        get { shouldFail.withLock { $0 } }
        set { shouldFail.withLock { $0 = newValue } }
    }
    var returnsEmpty: Bool {
        get { emptyResult.withLock { $0 } }
        set { emptyResult.withLock { $0 = newValue } }
    }

    func searchPlaces(keyword: String, near coordinate: Coordinate?) async throws -> [Place] {
        searchCalls.withLock { $0 += 1 }
        if fails { throw UpstreamError() }
        if returnsEmpty { return [] }
        return [makePlace("\(keyword) 결과")]
    }

    func reverseGeocode(_ coordinate: Coordinate) async throws -> Place {
        geocodeCalls.withLock { $0 += 1 }
        if fails { throw UpstreamError() }
        return makePlace("현위치")
    }

    func isServiceRegion(_ coordinate: Coordinate) async throws -> Bool {
        serviceRegionCalls.withLock { $0 += 1 }
        return true
    }
}

private func makePlace(_ name: String) -> Place {
    Place(name: name, address: "\(name) 주소", coordinate: Coordinate(latitude: 37.5, longitude: 127.0))
}

struct CachingPlaceRepositoryTests {
    private let upstream = SpyPlaceRepository()
    private let store = InMemoryKeyValueStore()

    private func makeSUT(ttl: Duration = .seconds(3600)) -> CachingPlaceRepository {
        CachingPlaceRepository(
            upstream: upstream,
            geocodeCache: ExpiringCache(
                store: store, key: "rgeo", ttl: ttl, limit: 10, jitter: { _ in 0 }
            ),
            searchCache: ExpiringCache(
                store: store, key: "search", ttl: ttl, limit: 10, jitter: { _ in 0 }
            )
        )
    }

    // MARK: - 적중

    @Test
    func reverseGeocode_secondCallSameCoordinate_doesNotHitUpstream() async throws {
        let sut = makeSUT()
        let coordinate = Coordinate(latitude: 37.5665, longitude: 126.9780)

        let first = try await sut.reverseGeocode(coordinate)
        let second = try await sut.reverseGeocode(coordinate)

        #expect(upstream.geocodeCount == 1)
        #expect(first == second)
    }

    /// GPS는 가만히 있어도 미터 단위로 떨린다. 반올림이 없으면 적중률이 사실상 0이 되고,
    /// 검색 화면에 들어갈 때마다 역지오코딩이 다시 돈다 — 이 캐시를 만든 이유 그 자체다.
    @Test
    func reverseGeocode_coordinateJitterWithinRounding_hitsCache() async throws {
        let sut = makeSUT()

        _ = try await sut.reverseGeocode(Coordinate(latitude: 37.56650, longitude: 126.97800))
        _ = try await sut.reverseGeocode(Coordinate(latitude: 37.566504, longitude: 126.978001))

        #expect(upstream.geocodeCount == 1)
    }

    @Test
    func reverseGeocode_differentCoordinate_goesToUpstream() async throws {
        let sut = makeSUT()

        _ = try await sut.reverseGeocode(Coordinate(latitude: 37.5665, longitude: 126.9780))
        _ = try await sut.reverseGeocode(Coordinate(latitude: 37.4979, longitude: 127.0276))

        #expect(upstream.geocodeCount == 2)
    }

    @Test
    func searchPlaces_sameKeywordAndBias_doesNotHitUpstream() async throws {
        let sut = makeSUT()
        let near = Coordinate(latitude: 37.5665, longitude: 126.9780)

        let first = try await sut.searchPlaces(keyword: "강남", near: near)
        let second = try await sut.searchPlaces(keyword: "강남", near: near)

        #expect(upstream.searchCount == 1)
        #expect(first == second)
    }

    /// 키워드는 공백·대소문자를 정규화한다 — 같은 검색이 두 키로 갈라지면 캐시가 논다.
    @Test
    func searchPlaces_keywordDiffersOnlyByWhitespaceOrCase_hitsCache() async throws {
        let sut = makeSUT()

        _ = try await sut.searchPlaces(keyword: "Gangnam", near: nil)
        _ = try await sut.searchPlaces(keyword: "  gangnam  ", near: nil)

        #expect(upstream.searchCount == 1)
    }

    @Test
    func searchPlaces_differentKeyword_goesToUpstream() async throws {
        let sut = makeSUT()

        _ = try await sut.searchPlaces(keyword: "강남", near: nil)
        _ = try await sut.searchPlaces(keyword: "홍대", near: nil)

        #expect(upstream.searchCount == 2)
    }

    /// near는 정렬 편향으로만 쓰이므로 110m 단위로 뭉갠다 — 더 잘게 쪼개면 걸어가는 동안
    /// 같은 키워드가 매번 새 키가 된다.
    ///
    /// 버킷 경계를 피한 좌표를 쓴다. 반올림 캐시는 경계를 사이에 둔 두 점이 갈라지는 게
    /// 정상 동작이라, 경계값으로 검증하면 테스트가 구현이 아니라 우연을 본다.
    @Test
    func searchPlaces_nearBiasWithinRounding_hitsCache() async throws {
        let sut = makeSUT()

        _ = try await sut.searchPlaces(keyword: "강남", near: Coordinate(latitude: 37.5660, longitude: 126.9780))
        _ = try await sut.searchPlaces(keyword: "강남", near: Coordinate(latitude: 37.56604, longitude: 126.97803))

        #expect(upstream.searchCount == 1)
    }

    /// near 유무는 다른 질의다 — 편향이 없으면 결과 순서가 달라진다.
    @Test
    func searchPlaces_nilBiasVersusCoordinate_areDifferentKeys() async throws {
        let sut = makeSUT()

        _ = try await sut.searchPlaces(keyword: "강남", near: nil)
        _ = try await sut.searchPlaces(keyword: "강남", near: Coordinate(latitude: 37.5665, longitude: 126.9780))

        #expect(upstream.searchCount == 2)
    }

    /// **빈 결과는 캐시하지 않는다.** 빈 배열도 성공 응답이라 그냥 담으면, 한 번 비어서 온
    /// 키워드가 원인이 사라진 뒤에도 TTL 내내 비어 보인다 — 화면이 스스로 회복하지 못한다.
    @Test
    func searchPlaces_emptyResult_isNotCached() async throws {
        let sut = makeSUT()
        upstream.returnsEmpty = true

        let first = try await sut.searchPlaces(keyword: "강남", near: nil)
        #expect(first.isEmpty)

        // 상류가 회복되면 같은 키워드가 **즉시** 결과를 돌려줘야 한다.
        upstream.returnsEmpty = false
        let second = try await sut.searchPlaces(keyword: "강남", near: nil)

        #expect(upstream.searchCount == 2)
        #expect(!second.isEmpty)
    }

    // MARK: - 캐시하지 않는 것

    /// 실패는 캐시하지 않는다. 지하철에서 한 번 실패한 키워드가 지상에 나와도 계속
    /// 실패로 답하면, 재시도 버튼이 의미를 잃는다.
    @Test
    func searchPlaces_upstreamFailure_isNotCached() async throws {
        let sut = makeSUT()
        upstream.fails = true

        await #expect(throws: UpstreamError.self) {
            _ = try await sut.searchPlaces(keyword: "강남", near: nil)
        }

        upstream.fails = false
        let recovered = try await sut.searchPlaces(keyword: "강남", near: nil)

        #expect(upstream.searchCount == 2)
        #expect(!recovered.isEmpty)
    }

    @Test
    func reverseGeocode_upstreamFailure_isNotCached() async throws {
        let sut = makeSUT()
        upstream.fails = true

        await #expect(throws: UpstreamError.self) {
            _ = try await sut.reverseGeocode(Coordinate(latitude: 37.5, longitude: 127.0))
        }

        upstream.fails = false
        _ = try await sut.reverseGeocode(Coordinate(latitude: 37.5, longitude: 127.0))

        #expect(upstream.geocodeCount == 2)
    }

    /// 서비스 지역 판정은 캐시하지 않는다 — 틀리면 **되는 지역을 막는다**. 호출도
    /// 집 주소 저장 시 1회뿐이라 아낄 왕복이 없다.
    @Test
    func isServiceRegion_alwaysGoesToUpstream() async throws {
        let sut = makeSUT()
        let coordinate = Coordinate(latitude: 37.5665, longitude: 126.9780)

        _ = try await sut.isServiceRegion(coordinate)
        _ = try await sut.isServiceRegion(coordinate)

        #expect(upstream.serviceRegionCount == 2)
    }
}
